#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: RFIN016
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/07/2018
Descrição---------: Relatório Previsão Reinf. Chamado 25552.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIN016()

Private _oReport := nil
Private _aOrder := {"Filial"}

Private _oSect0_A := Nil
Private _oSect1_A := Nil

Private _oSect0_B := Nil
Private _oSect1_B := Nil

Private _oSect0_C := Nil
Private _oSect1_C := Nil

Private _oSect0_D := Nil
Private _oSect1_D := Nil

Private _oSect0_G := Nil
Private _oSect1_G := Nil

Private _oSect0_H := Nil
Private _oSect1_H := Nil

Private _oSect0_I := Nil
Private _oSect1_I := Nil

Begin Sequence	
	
    // Gera a pergunta de modo oculto, ficando disponível no botão ações relacionadas
    Pergunte("RFIN016",.F.)	          

    // Chama a montagem do relatório.
	_oReport := RFIN016D("RFIN016")
	_oReport:PrintDialog()
	
End Sequence

Return

/*
===============================================================================================================================
Programa----------: RFIN016D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/07/2018
Descrição---------: Realiza as definições do relatório. (ReportDef)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN016D(_cNome)

Begin Sequence	
   _oReport := TReport():New(_cNome,"Relatório Previsão Reinf",_cNome,{|_oReport| RFIN016P(_oReport)},"Emissão do Relatorio Previsão Reinf")
   _oReport:SetLandscape()    
   _oReport:SetTotalInLine(.F.)
   
   // Define as totalizações e quebra por seção.
   //TRFunction():New(oSection2:Cell("B1_COD"),NIL,"COUNT",,,,,.F.,.T.)
   _oReport:SetTotalInLine(.F.)
   
   // Relatório A - R-2010 - Retenção Contribuição Previdenciária - Serviços Tomados - Documentos Fiscais (T013)
   _oSect0_A := TRSection():New(_oReport, "R-2010 - Retenção Contribuição Previdenciária - Serviços Tomados - Documentos Fiscais (T013)" , {"TRB_A"},_aOrder , .F., .T.)
   TRCell():New(_oSect0_A,"EVENTO"	,"TRB_A","Evento","@!",25) // R-2010-Documentos Fiscais (T013)
   
   _oSect1_A := TRSection():New(_oSect0_A, "R-2010 - Retenção Contribuição Previdenciária - Serviços Tomados - Documentos Fiscais (T013)" , {"TRB_A"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_A,"D1_FILIAL"	, "TRB_A"  ,"FILIAL"        ,"@!",07)	
   TRCell():New(_oSect1_A,"D1_DTDIGIT"	, "TRB_A"  ,"DATA DIGITAÇÃO","@!",14)	
   TRCell():New(_oSect1_A,"D1_EMISSAO"	, "TRB_A"  ,"DATA EMISSAO"  ,"@!",14)	
   
   TRCell():New(_oSect1_A,"F1_ESPECIE"	, "TRB_A"  ,"ESPECIE"       ,"@!",8)	
   
   TRCell():New(_oSect1_A,"A2_COD"	    , "TRB_A"  ,"FORNECEDOR"     ,"@!",12)        // Codigo do fornecedor
   TRCell():New(_oSect1_A,"A2_LOJA"	    , "TRB_A"  ,"LOJA FORN."     ,"@!",12)        // Loja do fornecedor
   TRCell():New(_oSect1_A,"A2_NOME"	    , "TRB_A"  ,"NOME FORNECEDOR","@!",40)        // Nome do fornecedor
   TRCell():New(_oSect1_A,"A2_CGC"      , "TRB_A"  ,"CNPJ"  ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ do fornecedor

   TRCell():New(_oSect1_A,"D1_DOC"	    , "TRB_A"  ,"NOTA FISCAL"   ,"@!",12)	
   TRCell():New(_oSect1_A,"D1_SERIE"	, "TRB_A"  ,"SERIE"         ,"@!",5)	
   TRCell():New(_oSect1_A,"D1_COD"	    , "TRB_A"  ,"PRODUTO"       ,"@!",15)	
   TRCell():New(_oSect1_A,"B1_DESC"	    , "TRB_A"  ,"DESC.PRODUTO"  ,"@!",30)	     // Descrição do produto.

   TRCell():New(_oSect1_A,"D1_BASEINS"	, "TRB_A"  ,"BASE INSS"     ,"@E 999,999,999,999.99",20)	
   TRCell():New(_oSect1_A,"D1_ALIQINS"	, "TRB_A"  ,"ALIQUOTA"      ,"@E 999,999.9999",10)	
   TRCell():New(_oSect1_A,"D1_VALINS"	, "TRB_A"  ,"VALOR INSS"    ,"@E 999,999,999,999.99",20)	
   TRCell():New(_oSect1_A,"OCORRENCIA"	, "TRB_A"  ,"OCORRENCIA"    ,"@!",80)	
   
   _oSect1_A:SetTotalText(" ")
   _oSect1_A:Disable()
   
   _oSect0_A:Disable() 

   // Relatório B - R-2010 - Retenção Contribuição Previdenciária - Serviços Tomados - Faturas (T154) 
   _oSect0_B := TRSection():New(_oReport, "R-2010 - Retenção Contribuição Previdenciária - Serviços Tomados - Faturas (T154)", {"TRB_B"},_aOrder , .F., .T.)
   TRCell():New(_oSect0_B,"EVENTO"	,"TRB_B","Evento","@!",25) // R-2010-Documentos Fiscais (T013)
   
   _oSect1_B := TRSection():New(_oSect0_B, "R-2010 - Retenção Contribuição Previdenciária - Serviços Tomados - Faturas (T154)", {"TRB_B"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_B,"E2_FILIAL"	, "TRB_B"  ,"FILIAL"          ,"@!",07)	
   TRCell():New(_oSect1_B,"E2_EMISSAO"	, "TRB_B"  ,"DATA EMISSAO"    ,"@!",14)	
   TRCell():New(_oSect1_B,"E2_NUM"	   , "TRB_B"  ,"NUM TITULO"      ,"@!",14)	
   TRCell():New(_oSect1_B,"E2_FORNECE"	, "TRB_B"  ,"FORNECEDOR "     ,"@!",12)	
   TRCell():New(_oSect1_B,"E2_LOJA"	   , "TRB_B"  ,"LOJA"            ,"@!",8)	
   TRCell():New(_oSect1_B,"E2_NOMFOR"	, "TRB_B"  ,"NOME FORNECEDOR" ,"@!",40)	
   TRCell():New(_oSect1_B,"A2_CGC"     , "TRB_B"  ,"CNPJ"  ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ do fornecedor
   TRCell():New(_oSect1_B,"E2_BASEINS"	, "TRB_B"  ,"BASE INSS"     ,"@E 999,999,999,999.99",20)	
   TRCell():New(_oSect1_B,"E2_INSS"	   , "TRB_B"  ,"VALOR INSS"    ,"@E 999,999,999,999.99",20)	
   TRCell():New(_oSect1_B,"OCORRENCIA"	, "TRB_B"  ,"OCORRENCIA"      ,"@!",80)	

   _oSect1_B:SetTotalText(" ")
   _oSect1_B:Disable()
   
   _oSect0_B:Disable()
   
   // Relatório C - R-2020 - Retenção Contribuição Previdenciária - Serviços Prestados - Documentos Fiscais (T013)
   _oSect0_C := TRSection():New(_oReport, "R-2020 - Retenção Contribuição Previdenciária - Serviços Prestados - Documentos Fiscais (T013)", {"TRB_C"},_aOrder , .F., .T.)
   TRCell():New(_oSect0_C,"EVENTO"	,"TRB_C","Evento","@!",25) // R-2010-Documentos Fiscais (T013)
   
   _oSect1_C := TRSection():New(_oSect0_C, "R-2020 - Retenção Contribuição Previdenciária - Serviços Prestados - Documentos Fiscais (T013)" , {"TRB_C"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_C,"D2_FILIAL"	, "TRB_C"  ,"FILIAL"       ,"@!",07)	
   TRCell():New(_oSect1_C,"D2_EMISSAO"	, "TRB_C"  ,"DATA EMISSAO" ,"@!",14)	
   TRCell():New(_oSect1_C,"F2_ESPECIE"	, "TRB_C"  ,"ESPECIE"      ,"@!",14)	

   TRCell():New(_oSect1_C,"A1_COD"	    , "TRB_C"  ,"CLIENTE"      ,"@!",09)    // Codigo do cliente
   TRCell():New(_oSect1_C,"A1_LOJA"	    , "TRB_C"  ,"LOJA"         ,"@!",08)    // Loja do cliente
   TRCell():New(_oSect1_C,"A1_NOME"	    , "TRB_C"  ,"NOME CLIENTE" ,"@!",40)    // Nome do cliente
   TRCell():New(_oSect1_C,"A1_CGC"      , "TRB_C"  ,"CNPJ"         ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ do fornecedor

   TRCell():New(_oSect1_C,"D2_DOC"	    , "TRB_C"  ,"NOTA FISCAL"  ,"@!",8)	
   TRCell():New(_oSect1_C,"D2_SERIE"    , "TRB_C"  ,"SERIE"        ,"@!",12)	
   TRCell():New(_oSect1_C,"D2_COD"	    , "TRB_C"  ,"PRODUTO"      ,"@!",5)	
 
   TRCell():New(_oSect1_C,"B1_DESC"     , "TRB_C"  ,"DESC.PRODUTO" ,"@!",30)	

   TRCell():New(_oSect1_C,"D2_BASEINS"	, "TRB_C"  ,"BASE INSS"    ,"@E 999,999,999,999.99",15)	
   TRCell():New(_oSect1_C,"D2_ALIQINS"	, "TRB_C"  ,"ALIQUOTA"     ,"@E 999,999.9999",20)	
   TRCell():New(_oSect1_C,"D2_VALINS"	, "TRB_C"  ,"VALOR INSS"   ,"@E 999,999,999,999.99",10)	
   TRCell():New(_oSect1_C,"OCORRENCIA"	, "TRB_C"  ,"OCORRENCIA"   ,"@!",80)	
   _oSect1_C:SetTotalText(" ")
   _oSect1_C:Disable()
   
   _oSect0_C:Disable()
   
   // Relatório D - R-2020 - Retenção Contribuição Previdenciária - Serviços Prestados - Faturas (T154) 
   _oSect0_D := TRSection():New(_oReport, "R-2020 - Retenção Contribuição Previdenciária - Serviços Prestados - Faturas (T154)", {"TRB_D"},_aOrder , .F., .T.)
   TRCell():New(_oSect0_D,"EVENTO"	,"TRB_D","Evento","@!",25) // R-2020-Faturas (T154)
   
   _oSect1_D := TRSection():New(_oSect0_D, "R-2020 - Retenção Contribuição Previdenciária - Serviços Prestados - Faturas (T154) " , {"TRB_D"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_D,"E1_FILIAL"	, "TRB_D"  ,"FILIAL"        ,"@!",07)	
   TRCell():New(_oSect1_D,"E1_EMISSAO"	, "TRB_D"  ,"DATA EMISSAO " ,"@!",14)	
   TRCell():New(_oSect1_D,"E1_NUM"	   , "TRB_D"  ,"NUM TITULO"    ,"@!",14)	
   TRCell():New(_oSect1_D,"E1_CLIENTE"	, "TRB_D"  ,"CLIENTE "      ,"@!",10)	
   TRCell():New(_oSect1_D,"E1_LOJA"	   , "TRB_D"  ,"LOJA "         ,"@!",08)	
   TRCell():New(_oSect1_D,"E1_NOMCLI"	, "TRB_D"  ,"NOME CLIENTE"  ,"@!",40)	
   TRCell():New(_oSect1_D,"A1_CGC"	   , "TRB_D"  ,"CNPJ"          ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ	
   TRCell():New(_oSect1_D,"OCORRENCIA"	, "TRB_D"  ,"OCORRENCIA"    ,"@!",80)	
   _oSect1_D:SetTotalText(" ")
   _oSect1_D:Disable()
    
   _oSect0_D:Disable() 

   // Relatório G - R-2040 - Retenção Contribuição Previdenciária - Serviços Tomados - Documentos Fiscais (T013)
   _oSect0_G := TRSection():New(_oReport, "R-2040 - Recursos Repassados para Associação Desportiva - Documentos Fiscais (T013)" , {"TRB_G"},_aOrder , .F., .T.)
   TRCell():New(_oSect0_G,"EVENTO"	,"TRB_G","Evento","@!",25) 
   
   _oSect1_G := TRSection():New(_oSect0_G, "R-2040 - Recursos Repassados para Associação Desportiva - Documentos Fiscais (T013)" , {"TRB_G"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_G,"D1_FILIAL"	, "TRB_G"  ,"FILIAL"        ,"@!",07)	
   TRCell():New(_oSect1_G,"D1_DTDIGIT"	, "TRB_G"  ,"DATA DIGITAÇÃO","@!",14)	
   TRCell():New(_oSect1_G,"D1_EMISSAO"	, "TRB_G"  ,"DATA EMISSAO"  ,"@!",14)	
   TRCell():New(_oSect1_G,"F1_ESPECIE"	, "TRB_G"  ,"ESPECIE"       ,"@!",8)	

   TRCell():New(_oSect1_G,"A2_COD"	    , "TRB_G"  ,"FORNECEDOR"     ,"@!",12)	      // Codigo do fornecedor
   TRCell():New(_oSect1_G,"A2_LOJA"	    , "TRB_G"  ,"LOJA"           ,"@!",08)	     // Loja do fornecedor
   TRCell():New(_oSect1_G,"A2_NOME"	    , "TRB_G"  ,"NOME FORNECEDOR","@!",40)	     // Nome do fornecedor
   TRCell():New(_oSect1_G,"A2_CGC"      , "TRB_G"  ,"CNPJ"  ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ do fornecedor

   TRCell():New(_oSect1_G,"D1_DOC"	    , "TRB_G"  ,"NOTA FISCAL"   ,"@!",12)	
   TRCell():New(_oSect1_G,"D1_SERIE"	, "TRB_G"  ,"SERIE"         ,"@!",5)	
   TRCell():New(_oSect1_G,"D1_COD"	    , "TRB_G"  ,"PRODUTO"       ,"@!",15)

   TRCell():New(_oSect1_G,"B1_DESC"	    , "TRB_G"  ,"DESC.PRODUTO"  ,"@!",30)
  	
   TRCell():New(_oSect1_G,"D1_BASEINS"	, "TRB_G"  ,"BASE INSS"     ,"@E 999,999,999,999.99",18)	
   TRCell():New(_oSect1_G,"D1_ALIQINS"	, "TRB_G"  ,"ALIQUOTA"      ,"@E 999,999.9999",12)	
   TRCell():New(_oSect1_G,"D1_VALINS"	, "TRB_G"  ,"VALOR INSS"    ,"@E 999,999,999,999.99",18)	
   TRCell():New(_oSect1_G,"OCORRENCIA"	, "TRB_G"  ,"OCORRENCIA"    ,"@!",80)	
   _oSect1_G:SetTotalText(" ")
   _oSect1_G:Disable()
   
   _oSect0_G:Disable()
   
   // Relatório H - R-2040 - Retenção Contribuição Previdenciária - Serviços Tomados - Documentos Fiscais (T013)
   _oSect0_H := TRSection():New(_oReport, "R-2040 - Recursos Repassados para Associação Desportiva - Faturas (T154)" , {"TRB_H"},_aOrder , .F., .T.)
   TRCell():New(_oSect0_H,"EVENTO"	,"TRB_H","Evento","@!",25) 
   
   _oSect1_H := TRSection():New(_oSect0_H, "R-2040 - Recursos Repassados para Associação Desportiva - Faturas (T154)" , {"TRB_H"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_H,"E2_FILIAL"	, "TRB_H"  ,"FILIAL"          ,"@!",07)	
   TRCell():New(_oSect1_H,"E2_EMISSAO"	, "TRB_H"  ,"DATA EMISSAO"    ,"@!",14)	
   TRCell():New(_oSect1_H,"E2_NUM"	   , "TRB_H"  ,"NUM TITULO "     ,"@!",14)	
   TRCell():New(_oSect1_H,"E2_FORNECE"	, "TRB_H"  ,"FORNECEDOR"      ,"@!",14)	
   TRCell():New(_oSect1_H,"E2_LOJA"	   , "TRB_H"  ,"LOJA"            ,"@!",8)	
   TRCell():New(_oSect1_H,"E2_NOMFOR"	, "TRB_H"  ,"NOME FORNECEDOR" ,"@!",40)	
   TRCell():New(_oSect1_H,"A2_CGC"     , "TRB_H"  ,"CNPJ"  ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ do fornecedor
   TRCell():New(_oSect1_H,"E2_BASEINS"	, "TRB_H"  ,"BASE INSS"     ,"@E 999,999,999,999.99",20)	
   TRCell():New(_oSect1_H,"E2_INSS"	   , "TRB_H"  ,"VALOR INSS"    ,"@E 999,999,999,999.99",20)	
   TRCell():New(_oSect1_H,"OCORRENCIA"	, "TRB_H"  ,"OCORRENCIA"      ,"@!",80)	
   _oSect1_H:SetTotalText(" ")
   _oSect1_H:Disable()
   
   _oSect0_H:Disable()

   // Relatório I - R-2055 - Aquisição Produtor Rural - Documentos Fiscais (T013)
   _oSect0_I := TRSection():New(_oReport, "R-2055 - Aquisição Produtor Rural - Documentos Fiscais (T013)" , {"TRB_I"},_aOrder , .F., .T.)
   TRCell():New(_oSect0_I,"EVENTO"	,"TRB_I","Evento","@!",25) // R-2055 - Documentos Fiscais (T013)
   
   _oSect1_I := TRSection():New(_oSect0_I, "R-2055 - Aquisição Produtor Rural - Documentos Fiscais (T013)" , {"TRB_I"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_I,"D1_FILIAL"	, "TRB_I"  ,"FILIAL"        ,"@!",07)	
   TRCell():New(_oSect1_I,"D1_DTDIGIT"	, "TRB_I"  ,"DATA DIGITAÇÃO","@!",14)	
   TRCell():New(_oSect1_I,"D1_EMISSAO"	, "TRB_I"  ,"DATA EMISSAO"  ,"@!",14)	
   
   TRCell():New(_oSect1_I,"F1_ESPECIE"	, "TRB_I"  ,"ESPECIE"       ,"@!",8)	
   
   TRCell():New(_oSect1_I,"A2_COD"	    , "TRB_I"  ,"FORNECEDOR"     ,"@!",12)             // Codigo do fornecedor
   TRCell():New(_oSect1_I,"A2_LOJA"	    , "TRB_I"  ,"LOJA FORN."     ,"@!",12)             // Loja do fornecedor
   TRCell():New(_oSect1_I,"A2_NOME"	    , "TRB_I"  ,"NOME FORNECEDOR","@!",40)             // Nome do fornecedor
   TRCell():New(_oSect1_I,"A2_CGC"      , "TRB_I"  ,"CNPJ"  ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ do fornecedor
   
   TRCell():New(_oSect1_I,"A2_INDCP"    , "TRB_I"  ,"Indicativo Rural"  ,"@!",16)          // Indicativo Rural // JPP TESTE

   TRCell():New(_oSect1_I,"D1_DOC"	    , "TRB_I"  ,"NOTA FISCAL"   ,"@!",12)	 
   TRCell():New(_oSect1_I,"D1_SERIE"	, "TRB_I"  ,"SERIE"         ,"@!",5)	 
   TRCell():New(_oSect1_I,"D1_COD"	    , "TRB_I"  ,"PRODUTO"       ,"@!",15)	 
   TRCell():New(_oSect1_I,"B1_DESC"	    , "TRB_I"  ,"DESC.PRODUTO"  ,"@!",30)	      // Descrição do produto.

   TRCell():New(_oSect1_I,"D1_BASEINS"	, "TRB_I"  ,"BASE INSS"        ,"@E 999,999,999,999.99",20)	 
   TRCell():New(_oSect1_I,"D1_ALIQINS"	, "TRB_I"  ,"ALIQUOTA"         ,"@E 999,999.9999",10)	 
   TRCell():New(_oSect1_I,"D1_VALINS"	, "TRB_I"  ,"VALOR INSS"       ,"@E 999,999,999,999.99",20)	 
   TRCell():New(_oSect1_I,"D1_BSSENAR"	, "TRB_I"  ,"BASE SENAR"       ,"@E 999,999,999,999.99",20)
   TRCell():New(_oSect1_I,"D1_ALSENAR"	, "TRB_I"  ,"ALIQUOTA SENAR"   ,"@E 999,999.9999",10)
   TRCell():New(_oSect1_I,"D1_VLSENAR"	, "TRB_I"  ,"VALOR SENAR"      ,"@E 999,999,999,999.99",20)
   TRCell():New(_oSect1_I,"D1_BASEFUN"	, "TRB_I"  ,"BASE FUNRURAL"    ,"@E 999,999,999,999.99",20)
   TRCell():New(_oSect1_I,"D1_ALIQFUN"	, "TRB_I"  ,"ALIQUOTA FUNRURAL","@E 999,999.9999",10)
   TRCell():New(_oSect1_I,"D1_VALFUN"	, "TRB_I"  ,"VALOR FUNRURAL"   ,"@E 999,999,999,999.99",20)
   TRCell():New(_oSect1_I,"OCORRENCIA"	, "TRB_I"  ,"OCORRENCIA"       ,"@!",80)	
   
   _oSect1_I:SetTotalText(" ")
   _oSect1_I:Disable()
   
   _oSect0_I:Disable() 
   
End Sequence
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------: RFIN016P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/06/2016
Descrição---------: Realiza a impressão do relatório. (ReportPrint)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN016P(_oReport)
Local _lTodos := .F.

Begin Sequence     
   
   // Ativa a seção do relatório conforme seleção do relatório a ser emitido.
   If Empty(MV_PAR05)
      _lTodos := .T.
   EndIf
   
   // R-2010 - Retenção Contribuição Previdenciária - Serviços Tomados
   If _lTodos .Or. "R-2010" $ MV_PAR05
      
      // R-2010 - Documentos Fiscais (T013)
      _oSect0_A:Enable() 
      _oSect1_A:Enable() 
      RFIN016A()
      
      // R-2010 - Faturas (T154)
      _oSect0_B:Enable()	
      _oSect1_B:Enable() 
      RFIN016C()
      
   EndIf
   
   // R-2020 - Retenção Contribuição Previdenciária - Serviços Prestados
   If _lTodos .Or. "R-2020" $ MV_PAR05
      
      // R-2020 - Documentos Fiscais (T013)	
      _oSect0_C:Enable() 
      _oSect1_C:Enable()
      RFIN016E()
      
      // R-2020 - Faturas (T154)
      _oSect0_D:Enable()
      _oSect1_D:Enable()
      RFIN016F()
   EndIf
  
   // R-2040 - Retenção Contribuição Previdenciária - Serviços Tomados 
   If _lTodos .Or. "R-2040" $ MV_PAR05
      // R-2040 - Documentos Fiscais (T013)
      _oSect0_G:Enable()
      _oSect1_G:Enable() 
      RFIN016I()
      
      // R-2040 - Faturas (T154)
      _oSect0_H:Enable() 
      _oSect1_H:Enable() 
      RFIN016J()
      
   EndIf

   If _lTodos .Or. "R-2055" $ MV_PAR05
      // R-2055 - Aquisição Produtor Rural - Documentos Fiscais (T013) 	
      _oSect0_I:Enable()
      _oSect1_I:Enable() 
      RFIN016K()
   EndIf
 
End Sequence

Return

/*
===============================================================================================================================
Programa----------: RFIN016A()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 24/07/2018
Descrição---------: Gera os dados e imprime o relatório.
                    R-2010 - Retenção Contribuição Previdenciária - Serviços Tomados
                    R-2010 - Documentos Fiscais (T013)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN016A()
Local _cQry 
Local _nTotRegs
Local _cOcorrencia
Local _cRetorno

Begin Sequence
   _cQry := U_RFIN016Q(1)
   
   If Select("TRB_A") > 0
	  TRB_A->(DBCloseArea())
   EndIf
   
   TCQUERY _cQry NEW ALIAS "TRB_A"	
   
   TCSetField('TRB_A',"D1_DTDIGIT","D",8,0)
   TCSetField('TRB_A',"D1_EMISSAO","D",8,0)
   	
   DBSelectArea("TRB_A")
   TRB_A->(DBGoTop())

   Count to _nTotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   TRB_A->(DBGoTop())
   
   // Inicializando a seção _oSect0_A	 
   _oSect0_A:Init()
   _oSect0_A:Cell("EVENTO"):SetValue("R-2010-Documentos Fiscais(T013)")
   _oSect0_A:PrintLine()
   
   // Inicializando a seção _oSect1_A 
   _oSect1_A:Init()

   _oReport:IncMeter()
   
   // Inicia processo de impressão.
   While !TRB_A->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf
          
      // Imprimindo a seção _oSect1_A 
      _oSect1_A:Cell("D1_FILIAL"):SetValue(TRB_A->D1_FILIAL)
      _oSect1_A:Cell("D1_DTDIGIT"):SetValue(TRB_A->D1_DTDIGIT)	
      _oSect1_A:Cell("D1_EMISSAO"):SetValue(TRB_A->D1_EMISSAO)
      _oSect1_A:Cell("F1_ESPECIE"):SetValue(TRB_A->F1_ESPECIE)	
      _oSect1_A:Cell("D1_DOC"):SetValue(TRB_A->D1_DOC)
      _oSect1_A:Cell("D1_SERIE"):SetValue(TRB_A->D1_SERIE)
      _oSect1_A:Cell("D1_COD"):SetValue(TRB_A->D1_COD)
      _oSect1_A:Cell("D1_BASEINS"):SetValue(TRB_A->D1_BASEINS)
      _oSect1_A:Cell("D1_ALIQINS"):SetValue(TRB_A->D1_ALIQINS)
      _oSect1_A:Cell("D1_VALINS"):SetValue(TRB_A->D1_VALINS)	

      _oSect1_A:Cell("A2_COD"):SetValue(TRB_A->A2_COD)    // Codigo do fornecedor
      _oSect1_A:Cell("A2_LOJA"):SetValue(TRB_A->A2_LOJA)  // Loja do fornecedor
      _oSect1_A:Cell("A2_NOME"):SetValue(TRB_A->A2_NOME)  // Nome do fornecedor    
      _oSect1_A:Cell("A2_CGC"):SetValue(TRB_A->A2_CGC)  
        
      _oSect1_A:Cell("B1_DESC"):SetValue(TRB_A->B1_DESC)  // Descrição do produto.

     _cOcorrencia := ""
     
     If Empty(TRB_A->B1_CODISS)
        _cOcorrencia += " OD01 - Produto sem código de serviço preenchido. "      // - Sistema verifica se o conteudo do campo D1_COD na tabela SB1, se o campo B1_CODISS  é igual " "
     EndIf
     
     If Empty(TRB_A->D1_CODISS)
	    _cOcorrencia += " OD02 - Nota Fiscal sem código de serviço preenchido. "  // - Sistema verifica se o conteudo do campo D1_CODISS é igual " "	
	 EndIf
	  
	 _cRetorno := Posicione("CCQ",1,xFilial("CCQ")+TRB_A->D1_CODISS,'CCQ_CODIGO')
	 
	 If Empty(_cRetorno)
	    _cOcorrencia += " OD03 - Codigo de serviço Inválido. "                    // - Sistema verifica o conteudo do campo D1_CODISS existe no campo CCQ->CCQ_CODIGO
	    _cOcorrencia += " OD04 - Produto sem amarração com tipo de serviço. "     // - Sistema verifica se o conteudo do campo D1_COD existe em algum registro da tabela CDN->CDN_PROD e CDN->CDN_TPSERV = " "
	 EndIf
	 
	 If ! Empty(_cRetorno)
	    _cRetorno := Posicione("CDN",1,xFilial("CDN")+_cRetorno+TRB_A->B1_COD,'CDN_PROD') // CDN_FILIAL+CDN_CODISS+CDN_PROD 
	    If Empty(_cRetorno)
	       _cOcorrencia += " OD04 - Produto sem amarração com tipo de serviço. "     // - Sistema verifica se o conteudo do campo D1_COD existe em algum registro da tabela CDN->CDN_PROD e CDN->CDN_TPSERV = " " 
	    Else
	       _cRetorno := Posicione("CDN",1,xFilial("CDN")+_cRetorno+TRB_A->B1_COD,'CDN_TPSERV') // CDN_FILIAL+CDN_CODISS+CDN_PROD 
	       If Empty(_cRetorno)
	          _cOcorrencia += " OD04 - Produto sem amarração com tipo de serviço. "     // - Sistema verifica se o conteudo do campo D1_COD existe em algum registro da tabela CDN->CDN_PROD e CDN->CDN_TPSERV = " " 
	       EndIf
	    EndIf
	 EndIf
	 
	 If ! Empty(_cRetorno)
	    _cRetorno := Posicione("CC8",1,xFilial("CC8")+_cRetorno,'CC8_CODIGO') // CDN_FILIAL+CDN_CODISS+CDN_PROD 
	    If Empty(_cRetorno)
	       _cOcorrencia += " OD05 - Amarração Tipo de serviço Incorreta. "     // - Sistema verifica se o conteudo do campo D1_COD existe em algum registro da tabela CDN->CDN_PROD e CDN->CDN_TPSERV <> " ", se sim,
	 											                               //   verifica se o conteudo do campo CDN_TPSERV existe no campo CC8->CC8_CODIGO   
	    EndIf
	 EndIf
	 											                               
	 If TRB_A->D1_ALIQINS > 11										                               
	    _cOcorrencia += " OD06 - Aliquota INSS inválida. "                     // - Verifica se o valor do conteudo do campo D1_ALIQINS é maior que "11"	   
	 EndIf
     _oSect1_A:Cell("OCORRENCIA"):SetValue(_cOcorrencia)
     
     _oSect1_A:PrintLine()
 
     TRB_A->(DBSkip())
   EndDo   
   
   // Imprime linha separadora.
   _oReport:ThinLine()
 	
   // Finaliza primeira seção.  
   _oSect1_A:Finish()
   
   // Finaliza seção Zero.	  
   _oSect0_A:Finish()

End Sequence

If Select("TRB_A") > 0
   TRB_A->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIN016C()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 24/07/2018
Descrição---------: Gera os dados e imprime o relatório.
                    R-2010 - Retenção Contribuição Previdenciária - Serviços Tomados
                    R-2010 - Faturas (T154)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN016C()
Local _cQry 
Local _nTotRegs
Local _cOcorrencia
Local _cRetorno

Begin Sequence

   _cQry := U_RFIN016Q(2)
   
   If Select("TRB_B") > 0
	  TRB_B->(DBCloseArea())
   EndIf
   
   TCQUERY _cQry NEW ALIAS "TRB_B"	
   
   TCSetField('TRB_B',"E2_EMISSAO","D",8,0)
   	
   DBSelectArea("TRB_B")
   TRB_B->(DBGoTop())

   Count to _nTotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   TRB_B->(DBGoTop())
   
   // Inicializando a seção _oSect0_B 
   _oSect0_B:Init()
   _oSect0_B:Cell("EVENTO"):SetValue("R-2010-Faturas(T154)")
   _oSect0_B:PrintLine()
   
   // Inicializando a primeira seção 
   _oSect1_B:Init()
        
   // Inicia processo de impressão.
   While !TRB_B->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf
      
	  _oReport:IncMeter()
	          
      // Imprimindo a seção _oSect1_B	 
      _oSect1_B:Cell("E2_FILIAL"):SetValue(TRB_B->E2_FILIAL)
      _oSect1_B:Cell("E2_EMISSAO"):SetValue(TRB_B->E2_EMISSAO)
      _oSect1_B:Cell("E2_NUM"):SetValue(TRB_B->E2_NUM)
      _oSect1_B:Cell("E2_FORNECE"):SetValue(TRB_B->E2_FORNECE)
      _oSect1_B:Cell("E2_LOJA"):SetValue(TRB_B->E2_LOJA)
      _oSect1_B:Cell("E2_NOMFOR"):SetValue(TRB_B->E2_NOMFOR)
      _oSect1_B:Cell("A2_CGC"):SetValue(TRB_B->A2_CGC)  
      _oSect1_B:Cell("E2_BASEINS"):SetValue(TRB_B->E2_BASEINS)  
      _oSect1_B:Cell("E2_INSS"):SetValue(TRB_B->E2_INSS)  
      
      _cOcorrencia := ""
       
      If Empty(TRB_B->FKF_TPSERV)
         _cOcorrencia += " OT51 - Titulo sem complemento de Imposto. "  //   Sistema procura a chave do titulo posicionado na tabela FK7->FK7_CHAVE e localizando procura o conteudo do campo FK7->FK7_IDDOC
	   EndIf											                    //   no campo FKF_FKFIDDOC e verifica se o campo FKF->FKF_TPSERV = " "
      
      _cRetorno := ""
      
      If ! Empty(TRB_B->FKF_TPSERV)
         _cRetorno := Posicione("CC8",1,xFilial("CC8")+TRB_B->FKF_TPSERV,'CC8_CODIGO') // CC8_FILIAL+CC8_CODIGO
      EndIf
      
      If Empty(_cRetorno)
         _cOcorrencia += " OT52 - Titulo com complemento de Imposto Incorreto. "  //    Sistema procura a chave do titulo posicionado na tabela FK7->FK7_CHAVE e localizando procura o conteudo do campo FK7->FK7_IDDOC
	  EndIf											                              //    no campo FKF_FKFIDDOC e verifica no registro posicionado se o campo FKF->FKF_TPSERV <> " ", se sim verifica se o conteudo do campo FKF_TPSERV existe no campo CC8->CC8_CODIGO
	   
      _oSect1_B:Cell("OCORRENCIA"):SetValue(_cOcorrencia)
      
	  _oSect1_B:PrintLine()
 
      TRB_B->(DBSkip())
   EndDo   
   
   // Imprime linha separadora.
   _oReport:ThinLine()
 	
   // Finaliza primeira seção.  
   _oSect1_B:Finish()
   
   // Finaliza seção Zero.  
   _oSect0_B:Finish()

End Sequence

If Select("TRB_B") > 0
   TRB_B->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIN016E()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 24/07/2018
Descrição---------: Gera os dados e imprime o relatório.
                    R-2020 - Retenção Contribuição Previdenciária - Serviços Prestados
                    R-2020 - Documentos Fiscais (T013)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN016E()
Local _cQry 
Local _nTotRegs
Local _cOcorrencia

Begin Sequence
   _cQry := U_RFIN016Q(3)
   
   If Select("TRB_C") > 0
	  TRB_C->(DBCloseArea())
   EndIf
   
   TCQUERY _cQry NEW ALIAS "TRB_C"	
   
   TCSetField('TRB_C',"D2_EMISSAO","D",8,0)
   	
   DBSelectArea("TRB_C")
   TRB_C->(DBGoTop())

   Count to _nTotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   TRB_C->(DBGoTop())
   
   // Inicializando a seção _oSect0_C 
   _oSect0_C:Init()
   _oSect0_C:Cell("EVENTO"):SetValue("R-2020-Documentos Fiscais(T013)")
   _oSect0_C:PrintLine()
   
   // Inicializando a primeira seção 
    _oSect1_C:Init()
    
   // Inicia processo de impressão.
   While !TRB_C->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf
      
	  _oReport:IncMeter()
	         
      // Imprimindo a seção _oSect1_C	 
      _oSect1_C:Cell("D2_FILIAL"):SetValue(TRB_C->D2_FILIAL)	
      _oSect1_C:Cell("D2_EMISSAO"):SetValue(TRB_C->D2_EMISSAO)	
      _oSect1_C:Cell("F2_ESPECIE"):SetValue(TRB_C->F2_ESPECIE)	
      _oSect1_C:Cell("D2_DOC"):SetValue(TRB_C->D2_DOC)	
      _oSect1_C:Cell("D2_SERIE"):SetValue(TRB_C->D2_SERIE)	
      _oSect1_C:Cell("D2_COD"):SetValue(TRB_C->D2_COD)		   	
      _oSect1_C:Cell("D2_BASEINS"):SetValue(TRB_C->D2_BASEINS)	
      _oSect1_C:Cell("D2_ALIQINS"):SetValue(TRB_C->D2_ALIQINS)	
      _oSect1_C:Cell("D2_VALINS"):SetValue(TRB_C->D2_VALINS)	

      _oSect1_C:Cell("A1_COD"):SetValue(TRB_C->A1_COD)      // Codigo do cliente
      _oSect1_C:Cell("A1_LOJA"):SetValue(TRB_C->A1_LOJA)    // Loja do cliente
      _oSect1_C:Cell("A1_NOME"):SetValue(TRB_C->A1_NOME)    // Nome do cliente  
      _oSect1_C:Cell("A1_CGC"):SetValue(TRB_C->A1_CGC)   

      _oSect1_C:Cell("B1_DESC"):SetValue(TRB_C->B1_DESC)    // Descrição do Produto	
      
      _cOcorrencia := ""
      
      _cRetorno := Posicione("SB1",1,xFilial("SB1")+TRB_C->D2_COD,'B1_CODISS') 
      
      If Empty(_cRetorno)
         _cOcorrencia += " OD11 - Produto sem código de serviço preenchido. "      // - Sistema verifica se o conteudo do campo D2_COD na tabela SB1->B1_CODISS é diferente de " "
      EndIf
      
      If Empty(TRB_C->D2_CODISS)
	     _cOcorrencia += " OD12 - Nota Fiscal sem código de serviço preenchido. "  // - Sistema verifica se o conteudo do campo D2_CODISS é diferente de " "	
	  EndIf
	  
	  _cRetorno := Posicione("CCQ",1,xFilial("CCQ")+TRB_C->D2_CODISS,'CCQ_CODIGO')
	  
	  If Empty(_cRetorno)
	     _cOcorrencia += " OD13 - Codigo de serviço Inválido. "                    // - Sistema verifica o conteudo do campo D2_CODISS existe no campo CCQ->CCQ_CODIGO
	  EndIf
	 	 
	  If ! Empty(_cRetorno)
	     _cRetorno := Posicione("CDN",1,xFilial("CDN")+_cRetorno+TRB_C->D2_COD,'CDN_PROD') // CDN_FILIAL+CDN_CODISS+CDN_PROD 
	     If Empty(_cRetorno)
	        _cOcorrencia += " OD14 - Produto sem amarração com tipo de serviço. "     // - Sistema verifica se o conteudo do campo D2_COD existe em algum registro da tabela CDN->CDN_PROD e CDN->CDN_TPSERV <> " "
	     Else
	        _cRetorno := Posicione("CDN",1,xFilial("CDN")+_cRetorno+TRB_C->D2_COD,'CDN_TPSERV') // CDN_FILIAL+CDN_CODISS+CDN_PROD 
	        If Empty(_cRetorno)
	           _cOcorrencia += " OD15 - Amarração Tipo de serviço Incorreta. "           // - Sistema verifica se o conteudo do campo D2_COD existe em algum registro da tabela CDN->CDN_PROD e CDN->CDN_TPSERV <> " ", se sim,
											                                             //   verifica se o conteudo do campo CDN_TPSERV existe no campo CC8->CC8_CODIGO
	        EndIf
	     EndIf
	  EndIf

	  If TRB_C->D2_ALIQINS > 11 
	     _cOcorrencia += " OD16 - Aliquota INSS inválida. "                              // - Verifica se o valor do conteudo do campo D2_ALIQINS é maior que "11"
      EndIf
      
      _oSect1_C:Cell("OCORRENCIA"):SetValue(_cOcorrencia)	
      
	  _oSect1_C:PrintLine()
 
      TRB_C->(DBSkip())
   EndDo   
   
   // Imprime linha separadora.
   _oReport:ThinLine()
 	
   // Finaliza primeira seção.	  
   _oSect1_C:Finish()
   
   // Finaliza seção Zero. 	  
   _oSect0_C:Finish()
   
End Sequence

If Select("TRB_C") > 0
   TRB_C->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIN016F()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 24/07/2018
Descrição---------: Gera os dados e imprime o relatório.
                    R-2020 - Retenção Contribuição Previdenciária - Serviços Prestados      
                    R-2020 - Faturas (T154)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN016F()
Local _cQry 
Local _nTotRegs
Local _cOcorrencia

Begin Sequence
   _cQry := U_RFIN016Q(4)
   
   If Select("TRB_D") > 0
	  TRB_D->(DBCloseArea())
   EndIf
   
   TCQUERY _cQry NEW ALIAS "TRB_D"	
   
   TCSetField('TRB_D',"E1_EMISSAO","D",8,0)
   	
   DBSelectArea("TRB_D")
   TRB_D->(DBGoTop())

   Count to _nTotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   TRB_D->(DBGoTop())

   // Inicializando a seção _oSect0_D	 
   _oSect0_D:Init()
   _oSect0_D:Cell("EVENTO"):SetValue("R-2020-Faturas(T154)")
   _oSect0_D:PrintLine()
   
   // Inicializando a primeira seção 
   _oSect1_D:Init()
   
   // Inicia processo de impressão.	
   While !TRB_D->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf

	  _oReport:IncMeter()
	          
      // Imprimindo a seção _oSect1_D	 
      _oSect1_D:Cell("E1_FILIAL"):SetValue(TRB_D->E1_FILIAL)
      _oSect1_D:Cell("E1_EMISSAO"):SetValue(TRB_D->E1_EMISSAO )
      _oSect1_D:Cell("E1_NUM"):SetValue(TRB_D->E1_NUM )
      _oSect1_D:Cell("E1_CLIENTE"):SetValue(TRB_D->E1_CLIENTE)
      _oSect1_D:Cell("E1_LOJA"):SetValue(TRB_D->E1_LOJA)
      _oSect1_D:Cell("E1_NOMCLI"):SetValue(TRB_D->E1_NOMCLI)
      _oSect1_D:Cell("A1_CGC"):SetValue(TRB_D->A1_CGC)
      
      _cOcorrencia := ""
      If Empty(TRB_D->FKF_TPSERV)
         _cOcorrencia += " OT61 - Titulo sem complemento de Imposto. "  // - Regra : Sistema procura a chave do titulo posicionado na tabela FK7->FK7_CHAVE e localizando procura o conteudo do campo FK7->FK7_IDDOC
      EndIf										                        //   no campo FKF_FKFIDDOC e verifica se o campo FKF->FKF_TPSERV = " "
					
	  _cRetorno := ""											     
	  If ! Empty(TRB_D->FKF_TPSERV)
        _cRetorno := Posicione("CC8",1,xFilial("CC8")+TRB_D->FKF_TPSERV,'CC8_CODIGO') // CC8_FILIAL+CC8_CODIGO
     EndIf
      				
      If Empty(_cRetorno)											     
	     _cOcorrencia += " OT62 - Titulo com complemento de Imposto Incorreto. "  //  : Sistema procura a chave do titulo posicionado na tabela FK7->FK7_CHAVE e localizando procura o conteudo do campo FK7->FK7_IDDOC
	  EndIf 											                          //    no campo FKF_FKFIDDOC e verifica no registro posicionado se o campo FKF->FKF_TPSERV <> " ", se sim verifica se o conteudo do campo FKF_TPSERV existe no campo CC8->CC8_CODIGO
      
      _oSect1_D:Cell("OCORRENCIA"):SetValue(_cOcorrencia )

	  _oSect1_D:PrintLine()

      TRB_D->(DBSkip())
   EndDo   
   
   // Imprime linha separadora.
   _oReport:ThinLine()
 	
   // Finaliza primeira seção.	  
   _oSect1_D:Finish()
   
   // Finaliza seção Zero.  
   _oSect0_D:Finish()
   
End Sequence

If Select("TRB_D") > 0
   TRB_D->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIN016I()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 24/07/2018
Descrição---------: Gera os dados e imprime o relatório.
                    R-2040 - Retenção Contribuição Previdenciária - Serviços Tomados 
                    R-2040 - Documentos Fiscais (T013)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN016I()
Local _cQry 
Local _nTotRegs
Local _cOcorrencia

Begin Sequence
   _cQry := U_RFIN016Q(5)
   
   If Select("TRB_G") > 0
	  TRB_G->(DBCloseArea())
   EndIf
   
   TCQUERY _cQry NEW ALIAS "TRB_G"	
   
   TCSetField('TRB_G',"D1_DTDIGIT","D",8,0)
   TCSetField('TRB_G',"D1_EMISSAO","D",8,0)
   	
   DBSelectArea("TRB_G")
   TRB_G->(DBGoTop())

   Count to _nTotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   TRB_G->(DBGoTop())
   
   // Inicializando a seção _oSect0_F	 
   _oSect0_G:Init()
   _oSect0_G:Cell("EVENTO"):SetValue("R-2040-Documentos Fiscais(T013)")
   _oSect0_G:PrintLine()
   
   // Inicializando a primeira seção 
   _oSect1_G:Init()
	     
   // Inicia processo de impressão.	
   While !TRB_G->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf

	  _oReport:IncMeter()
	          
      // Imprimindo a seção _oSect1_G	 
      _oSect1_G:Cell("D1_FILIAL"):SetValue(TRB_G->D1_FILIAL)
      _oSect1_G:Cell("D1_DTDIGIT"):SetValue(TRB_G->D1_DTDIGIT)
      _oSect1_G:Cell("D1_EMISSAO"):SetValue(TRB_G->D1_EMISSAO)
      _oSect1_G:Cell("F1_ESPECIE"):SetValue(TRB_G->F1_ESPECIE)
      _oSect1_G:Cell("D1_DOC"):SetValue(TRB_G->D1_DOC)
      _oSect1_G:Cell("D1_SERIE"):SetValue(TRB_G->D1_SERIE)
      _oSect1_G:Cell("D1_COD"):SetValue(TRB_G->D1_COD)
      _oSect1_G:Cell("D1_BASEINS"):SetValue(TRB_G->D1_BASEINS)
      _oSect1_G:Cell("D1_ALIQINS"):SetValue(TRB_G->D1_ALIQINS)
      _oSect1_G:Cell("D1_VALINS"):SetValue(TRB_G->D1_VALINS)

      _oSect1_G:Cell("A2_COD"):SetValue(TRB_G->A2_COD)     // Codigo do fornecedor
      _oSect1_G:Cell("A2_LOJA"):SetValue(TRB_G->A2_LOJA)   // Loja do fornecedor
      _oSect1_G:Cell("A2_NOME"):SetValue(TRB_G->A2_NOME)   // Nome do fornecedor
      _oSect1_G:Cell("A2_CGC"):SetValue(TRB_G->A2_CGC)  
      
      _oSect1_G:Cell("B1_DESC"):SetValue(TRB_G->B1_DESC) 

      _cOcorrencia := ""

      _cRetorno := Posicione("SB1",1,xFilial("SB1")+TRB_G->D1_COD,'B1_COD')
      If Empty(_cRetorno)
         _cOcorrencia += " OD31 - Produto sem código de serviço preenchido. "     // - Sistema verifica se o conteudo do campo D1_COD na tabela SB1->B1_COD é diferente de " "
      EndIf
      
      If Empty(TRB_G->D1_CODISS)      
	     _cOcorrencia += " OD32 - Nota Fiscal sem código de serviço preenchido. " // - Sistema verifica se o conteudo do campo D1_CODISS é diferente de " "	
	  EndIf
	  
	  _cRetorno := Posicione("CCQ",1,xFilial("CCQ")+TRB_G->D1_CODISS,'CCQ_CODIGO')
	  
	  If Empty(_cRetorno)
	  	 _cOcorrencia += " OD33 - Codigo de serviço Inválido. "                             //  Sistema verifica o conteudo do campo D1_CODISS existe no campo CCQ->CCQ_CODIGO
	  EndIf

      If ! Empty(_cRetorno)
	     _cRetorno := Posicione("CDN",1,xFilial("CDN")+_cRetorno+TRB_G->D1_COD,'CDN_PROD')  // CDN_FILIAL+CDN_CODISS+CDN_PROD 
	     If Empty(_cRetorno)
	        _cOcorrencia += " OD34 - Produto sem amarração com tipo de serviço. "    //  - Sistema verifica se o conteudo do campo D1_COD existe em algum registro da tabela CDN->CDN_PROD e CDN->CDN_TPSERV = " "
	     Else
	        _cRetorno := Posicione("CDN",1,xFilial("CDN")+TRB_G->D1_CODISS+TRB_G->D1_COD,'CDN_TPSERV') // CDN_FILIAL+CDN_CODISS+CDN_PROD 
	        If Empty(_cRetorno)
	           _cOcorrencia += " OD35 - Amarração Tipo de serviço Incorreta. "          //  Sistema verifica se o conteudo do campo D1_COD existe em algum registro da tabela CDN->CDN_PROD e CDN->CDN_TPSERV <> " ", se sim,
			EndIf									                                    //  verifica se o conteudo do campo CDN_TPSERV existe no campo CC8->CC8_CODIGO
	     EndIf
	  EndIf	

	  If TRB_G->D1_ALIQINS > 11
	     _cOcorrencia += " OD36 - Aliquota INSS inválida. "                             // - Verifica se o valor do conteudo do campo D1_ALIQINS é maior que "11"	   
      EndIf

      _oSect1_G:Cell("OCORRENCIA"):SetValue(_cOcorrencia)
      
	  _oSect1_G:PrintLine()
 
      TRB_G->(DBSkip())
   EndDo   
   
   // Imprime linha separadora.
   _oReport:ThinLine()
 	
   // Finaliza primeira seção. 
   _oSect1_G:Finish()
   
   // Finaliza seção Zero.  
   _oSect0_G:Finish()
   
End Sequence

If Select("TRB_G") > 0
   TRB_G->(DBCloseArea())
EndIf
   
Return

/*
===============================================================================================================================
Programa----------: RFIN016J()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 24/07/2018
Descrição---------: Gera os dados e imprime o relatório.
                    R-2040 - Retenção Contribuição Previdenciária - Serviços Tomados 
                    R-2040 - Faturas (T154)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN016J()
Local _cQry 
Local _nTotRegs
Local _cOcorrencia

Begin Sequence
   _cQry := U_RFIN016Q(6)
   
   If Select("TRB_H") > 0
	  TRB_H->(DBCloseArea())
   EndIf
   
   TCQUERY _cQry NEW ALIAS "TRB_H"	
   
   TCSetField('TRB_H',"E2_EMISSAO","D",8,0)
   	
   DBSelectArea("TRB_H")
   TRB_H->(DBGoTop())

   Count to _nTotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   TRB_H->(DBGoTop())
   
   // Inicializando a seção _oSect0_H	 
   _oSect0_H:Init()
   _oSect0_H:Cell("EVENTO"):SetValue("R-2040-Faturas(T154)")
   _oSect0_H:PrintLine()
   
   // Inicializando a primeira seção	 
   _oSect1_H:Init()
   
   // Inicia processo de impressão.	
   While !TRB_H->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf
					
      // Inicializando a primeira seção		 
	  _oSect1_H:Init()

	  _oReport:IncMeter()
	          
      // Imprimindo a seção _oSect1_H	 
      _oSect1_H:Cell("E2_FILIAL"):SetValue(TRB_H->E2_FILIAL)
      _oSect1_H:Cell("E2_EMISSAO"):SetValue(TRB_H->E2_EMISSAO)
      _oSect1_H:Cell("E2_NUM"):SetValue(TRB_H->E2_NUM)
      _oSect1_H:Cell("E2_FORNECE"):SetValue(TRB_H->E2_FORNECE)
      _oSect1_H:Cell("E2_LOJA"):SetValue(TRB_H->E2_LOJA)
      _oSect1_H:Cell("E2_NOMFOR"):SetValue(TRB_H->E2_NOMFOR)
      _oSect1_H:Cell("A2_CGC"):SetValue(TRB_H->A2_CGC)  
      _oSect1_H:Cell("E2_BASEINS"):SetValue(TRB_H->E2_BASEINS)  
      _oSect1_H:Cell("E2_INSS"):SetValue(TRB_H->E2_INSS)  
      
      _cOcorrencia := ""
      
      If Empty(TRB_H->FKF_TPSERV)
         _cOcorrencia += " OT81 - Titulo sem complemento de Imposto. " // Sistema procura a chave do titulo posicionado na tabela FK7->FK7_CHAVE e localizando procura o conteudo do campo FK7->FK7_IDDOC
												                       // no campo FKF_FKFIDDOC e verifica se o campo FKF->FKF_TPSERV = " "
      EndIf
      
      _cRetorno := ""											     
	   
      If ! Empty(TRB_H->FKF_TPSERV)
         _cRetorno := Posicione("CC8",1,xFilial("CC8")+TRB_H->FKF_TPSERV,'CC8_CODIGO') // CC8_FILIAL+CC8_CODIGO         
      EndIf
      				
      If Empty(_cRetorno)	
		 _cOcorrencia += " OT82 - Titulo com complemento de Imposto Incorreto. " // Sistema procura a chave do titulo posicionado na tabela FK7->FK7_CHAVE e localizando procura o conteudo do campo FK7->FK7_IDDOC
												                                 // no campo FKF_FKFIDDOC e verifica no registro posicionado se o campo FKF->FKF_TPSERV <> " ", se sim verifica se o conteudo do campo FKF_TPSERV existe no campo CC8->CC8_CODIGO
      EndIf
      
      _oSect1_H:Cell("OCORRENCIA"):SetValue(_cOcorrencia)
      
	  _oSect1_H:PrintLine()
 
      TRB_H->(DBSkip())
   EndDo   
   
   // Imprime linha separadora.
   _oReport:ThinLine()
 	
   // Finaliza primeira seção.	  
   _oSect1_H:Finish()
   
   // Finaliza seção Zero.	  
   _oSect0_H:Finish()
   
End Sequence

If Select("TRB_H") > 0
   TRB_H->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIN016B
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/07/2018
Descrição---------: Retorna as opções da consulta específica utilizada na filtragem e emissão do relatório Previsão Reinf.
Parametros--------: Nenhum 
Retorno-----------: _aRet = Array com as opções da consulta tipo combobox.
===============================================================================================================================
*/
User Function RFIN016B()
Local _aRet

Begin Sequence
   _aRet := {"R-2010-Retenção Contribuição Previdenciária - Serviços Tomados",;
			 "R-2020-Retenção Contribuição Previdenciária - Serviços Prestados",;  // "R-2030-Recursos Recebidos por Associação Desportiva",;
			 "R-2040-Recursos Repassados para Associação Desportiva",;  // "R-2050-Comercialização da Produção por Produtor Rural PJ/Agroindústria",;
          "R-2055-Aquisição Produtor Rural - Documentos Fiscais (T013)",;
			 "R-2070-Retenções na Fonte - IR, CSLL, Cofins, PIS/PASEP"} 
End Sequence

Return _aRet

/*
===============================================================================================================================
Programa----------: RFIN016Q
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/07/2018
Descrição---------: Monta e retorna todas as querys utilizadas no relatório.
Parametros--------: _nQuery = numero da query.
Retorno-----------: _cQry = Query solicitada.
===============================================================================================================================
*/
User Function RFIN016Q(_nQuery)
Local _cQry := ""

Begin Sequence
   If _nQuery == 1 // RELATORIO A - R-2010 - Documentos Fiscais (T013):
      _cQry := " SELECT DISTINCT "
      _cQry += " D1_FILIAL, "    // FILIAL
      _cQry += " D1_DTDIGIT, "   // DATA DIGITAÇÃO 
      _cQry += " D1_EMISSAO, "   // DATA EMISSAO 
      _cQry += " F1_ESPECIE, "   // ESPECIE
      _cQry += " D1_DOC,    "    // NOTA FISCAL - 		
      _cQry += " D1_SERIE,  "    // SERIE
      _cQry += " D1_COD,    "    // PRODUTO
      _cQry += " D1_BASEINS, "   // BASE INSS 
      _cQry += " D1_ALIQINS, "   // ALIQUOTA 
      _cQry += " D1_VALINS, "    // VALOR INSS
      _cQry += " D1_CODISS, "    // OCORRENCIA
      _cQry += " D1_ALIQINS, "   // OCORRENCIA 
      _cQry += " B1_CODISS,  "   // OCORRENCIA 
      _cQry += " D1_CODISS,   "  // OCORRENCIA  
      _cQry += " B1_COD, "       // Codigo do produto.
      _cQry += " B1_DESC, "      // Codigo do produto.
      _cQry += " A2_COD, "       // Codigo do fornecedor
      _cQry += " A2_LOJA, "      // Loja do fornecedor
      _cQry += " A2_NOME, "       // Nome do fornecedor
      _cQry += " A2_CGC "
      _cQry += " FROM "+RetSqlName("SD1")+ " SD1, " + RetSqlName("SA2") + " SA2, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SF1") + " SF1 "  
      _cQry += " WHERE SD1.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' AND SF1.D_E_L_E_T_ = ' ' "
      _cQry += " AND D1_TPREPAS = ' ' AND D1_FORNECE = A2_COD AND D1_LOJA  = A2_LOJA AND A2_TIPO = 'J' AND A2_CGC <> ' ' AND A2_DESPORT = ' ' "    // (A2_DESPORT = ' ' OR A2_DESPORT = '0') "
      //_cQry += " AND B1_INSS = 'S' "
      _cQry += " AND D1_FORNECE = F1_FORNECE AND D1_LOJA  = F1_LOJA AND D1_FILIAL = F1_FILIAL AND F1_DOC = D1_DOC AND F1_SERIE = D1_SERIE "
      _cQry += " AND D1_VALINS > 0 AND D1_COD = B1_COD  "

      If ! Empty(MV_PAR01) // Filial  
         _cQry +=  " AND D1_FILIAL IN " + FormatIn(MV_PAR01,";")
      EndIf

      If ! Empty(MV_PAR02) // Data de  
      
         _cQry += " AND D1_EMISSAO >= '"+DToS(MV_PAR02)+"' " // D1_DTDIGIT
      EndIf
   
      If ! Empty(MV_PAR03) // Data até 
         _cQry += " AND D1_EMISSAO <= '"+DToS(MV_PAR03)+"' " // D1_DTDIGIT
      EndIf

      If ! Empty(MV_PAR04) // Produto
         _cQry +=  " AND D1_COD IN " + FormatIn(MV_PAR04,";")
      EndIf

   ElseIf _nQuery == 2 //  RELATORIO B - R-2010 - Faturas (T154) :	
      _cQry := " SELECT DISTINCT "
      _cQry +=  " E2_FILIAL,  " // FILIAL  		   	
      _cQry +=  " E2_EMISSAO, " // DATA EMISSAO 
      _cQry +=  " E2_NUM    , " // NUM TITULO 
      _cQry +=  " E2_FORNECE, " // FORNECEDOR 
      _cQry +=  " E2_LOJA   , " // LOJA
      _cQry +=  " E2_NOMFOR , " // NOME FORNECEDOR
      _cQry +=  " E2_PREFIXO, "
      _cQry +=  " E2_PARCELA, "
      _cQry +=  " E2_TIPO   , " 
      _cQry +=  " FK7_CHAVE,  "
      _cQry +=  " FK7_FILIAL, " 
      _cQry +=  " FK7_ALIAS,  "
      _cQry +=  " FKF_TPSERV,  "
      _cQry +=  " E2_BASEINS, "
      _cQry +=  " E2_INSS, "
      _cQry +=  " A2_CGC "
      _cQry +=  " FROM "+RetSqlName("SE2")+ " SE2, " + RetSqlName("FK7") + " FK7, " + RetSqlName("FKF") + " FKF, "+RetSqlName("SA2")+ " SA2 " 
      _cQry +=  " WHERE SE2.D_E_L_E_T_ = ' ' AND FK7.D_E_L_E_T_ = ' ' AND FKF.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' "
      _cQry +=  " AND E2_FILIAL  = FK7_FILTIT "
      _cQry +=  " AND E2_PREFIXO = FK7_PREFIX "
      _cQry +=  " AND E2_NUM     = FK7_NUM "
      _cQry +=  " AND E2_PARCELA = FK7_PARCEL "
      _cQry +=  " AND E2_TIPO    = FK7_TIPO "
      _cQry +=  " AND E2_FORNECE = FK7_CLIFOR "
      _cQry +=  " AND E2_LOJA    = FK7_LOJA "
      _cQry +=  " AND E2_FILIAL = FK7_FILIAL AND FK7_ALIAS = 'SE2' "
      _cQry +=  " AND E2_FORNECE = A2_COD AND E2_LOJA = A2_LOJA "
      _cQry +=  " AND FK7_FILIAL = FKF_FILIAL AND FK7_IDDOC = FKF_IDDOC "
      _cQry +=  " AND E2_INSS > 0 "
      _cQry +=  " AND E2_ORIGEM = 'FINA050' " // " AND E2_TITPAI = ' ' "
      _cQry +=  " AND A2_TIPO = 'J' "
      _cQry +=  " AND FKF_TPREPA = ' ' "
    
       If ! Empty(MV_PAR01) // Filial  
          _cQry +=  " AND E2_FILIAL IN " + FormatIn(MV_PAR01,";")
       EndIf

       If ! Empty(MV_PAR02) // Data de  
          _cQry += " AND E2_EMISSAO >= '"+DToS(MV_PAR02)+"' " 
       EndIf
   
       If ! Empty(MV_PAR03) // Data até 
          _cQry += " AND E2_EMISSAO <= '"+DToS(MV_PAR03)+"' "
       EndIf
   ElseIf _nQuery == 3 // RELATORIO C - R-2020 - Documentos Fiscais (T013):
      _cQry := " SELECT DISTINCT "
      _cQry += " D2_FILIAL,"      //    FILIAL
      _cQry += " D2_EMISSAO, "    //	DATA EMISSAO
      _cQry += " F2_ESPECIE, "    //	ESPECIE
      _cQry += " D2_DOC, "        //	NOTA FISCAL
      _cQry += " D2_SERIE, "      //	SERIE
      _cQry += " D2_COD, "        //    PRODUTO
      _cQry += " D2_BASEINS, "    //	BASE INSS
      _cQry += " D2_ALIQINS, "    //	ALIQUOTA 
      _cQry += " D2_VALINS, "     //    VALOR INSS
      _cQry += " D2_CODISS, " 
      _cQry += " B1_CODISS, "
      _cQry += " B1_DESC, "      // Codigo do produto.
      _cQry += " A1_COD, "       // Codigo do fornecedor
      _cQry += " A1_LOJA, "      // Loja do fornecedor
      _cQry += " A1_NOME, "       // Nome do fornecedor
      _cQry += " A1_CGC "
      _cQry += " FROM "+RetSqlName("SD2")+ " SD2, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SF2") + " SF2, " + RetSqlName("SA1")+ " SA1 " 
      _cQry += " WHERE SD2.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' AND SF2.D_E_L_E_T_ = ' ' AND SA1.D_E_L_E_T_ = ' ' "
      _cQry += " AND D2_CLIENTE = F2_CLIENTE AND D2_LOJA  = F2_LOJA AND D2_FILIAL = F2_FILIAL AND F2_DOC = D2_DOC AND F2_SERIE = D2_SERIE " 
      _cQry += " AND A1_COD = F2_CLIENTE AND A1_LOJA  = F2_LOJA "
      _cQry += " AND A1_PESSOA = 'J' AND A1_CGC <> ' ' " // AND B1_INSS = 'S'
      _cQry += " AND D2_VALINS > 0 AND D2_COD = B1_COD "

      If ! Empty(MV_PAR01) // Filial  
         _cQry +=  " AND D2_FILIAL IN " + FormatIn(MV_PAR01,";")
      EndIf

      If ! Empty(MV_PAR02) // Data de  
         _cQry += " AND D2_EMISSAO >= '"+DToS(MV_PAR02)+"' "
      EndIf
   
      If ! Empty(MV_PAR03) // Data até 
         _cQry += " AND D2_EMISSAO <= '"+DToS(MV_PAR03)+"' "
      EndIf

      If ! Empty(MV_PAR04) // Produto
         _cQry +=  " AND D2_COD IN " + FormatIn(MV_PAR04,";")
      EndIf
   ElseIf _nQuery == 4 // RELATORIO D -	R-2020 - Faturas (T154)
      _cQry :=  " SELECT DISTINCT "
      _cQry += " E1_FILIAL, "  // FILIAL  		   	
      _cQry += " E1_EMISSAO, " // DATA EMISSAO 
      _cQry += " E1_NUM    , "  // NUM TITULO 
      _cQry += " E1_CLIENTE, "  // CLIENTE 
      _cQry += " E1_LOJA   , "  // LOJA
      _cQry += " E1_NOMCLI , "  // NOME CLIENTE
      _cQry += " E1_PREFIXO, "
      _cQry += " E1_PARCELA, "
      _cQry += " E1_TIPO   , " 
      _cQry += " FK7_CHAVE, "
      _cQry += " FK7_FILIAL, " 
      _cQry += " FK7_ALIAS, "
      _cQry += " FKF_TPSERV,"
      _cQry += " A1_CGC "
      _cQry += " FROM "+RetSqlName("SE1")+ " SE1, " + RetSqlName("FK7") + " FK7, " + RetSqlName("FKF") + " FKF, "+RetSqlName("SA1")+ " SA1 " 
      _cQry += " WHERE SE1.D_E_L_E_T_ = ' ' AND FK7.D_E_L_E_T_ = ' ' AND FKF.D_E_L_E_T_ = ' ' AND SA1.D_E_L_E_T_ = ' ' "
      _cQry += " AND E1_FILIAL   = FK7_FILTIT "
      _cQry += " AND E1_PREFIXO  = FK7_PREFIX "
      _cQry += " AND E1_NUM      = FK7_NUM "
      _cQry += " AND E1_PARCELA  = FK7_PARCEL "
      _cQry += " AND E1_TIPO     = FK7_TIPO "
      _cQry += " AND E1_CLIENTE  = FK7_CLIFOR "
      _cQry += " AND E1_LOJA     = FK7_LOJA "
      _cQry += " AND E1_FILIAL = FK7_FILIAL AND FK7_ALIAS = 'SE1' "
      _cQry += " AND E1_CLIENTE = A1_COD AND E1_LOJA = A1_LOJA "
      _cQry += " AND FK7_FILIAL = FKF_FILIAL AND FK7_IDDOC = FKF_IDDOC "
      _cQry += " AND E1_INSS    > 0 "
      _cQry += " AND E1_ORIGEM = 'FINA040' "  // " AND E1_TITPAI = ' ' "
      _cQry += " AND A1_PESSOA = 'J' "
      _cQry += " AND FKF_TPREPA = ' ' "

      If ! Empty(MV_PAR01) // Filial  
         _cQry +=  " AND E1_FILIAL IN " + FormatIn(MV_PAR01,";")
      EndIf

      If ! Empty(MV_PAR02) // Data de  
         _cQry += " AND E1_EMISSAO >= '"+DToS(MV_PAR02)+"' "
      EndIf
   
      If ! Empty(MV_PAR03) // Data até 
         _cQry += " AND E1_EMISSAO <= '"+DToS(MV_PAR03)+"' "
      EndIf										  
       
   ElseIf _nQuery == 5 // 7 // RELATORIO G - R-2040 - Documentos Fiscais (T013):
       _cQry := " SELECT DISTINCT "
       _cQry += " D1_FILIAL,  " // FILIAL
       _cQry += " D1_DTDIGIT, " // DATA DIGITAÇÃO 
       _cQry += " D1_EMISSAO, " // DATA EMISSAO 
       _cQry += " F1_ESPECIE, " // ESPECIE
       _cQry += " D1_DOC,     " // NOTA FISCAL - 		
       _cQry += " D1_SERIE,   " // SERIE
       _cQry += " D1_COD,     " // PRODUTO
       _cQry += " D1_BASEINS, " // BASE INSS 
       _cQry += " D1_ALIQINS, " // ALIQUOTA 
       _cQry += " D1_VALINS,  " // VALOR INSS
       _cQry += " D1_CODISS,  " // OCORRENCIA
       _cQry += " D1_ALIQINS, " // OCORRENCIA 
       _cQry += " B1_CODISS,  " // OCORRENCIA 
       _cQry += " D1_CODISS,   " // OCORRENCIA 
       _cQry += " B1_DESC, "      // Codigo do produto.
       _cQry += " A2_COD, "       // Codigo do fornecedor
       _cQry += " A2_LOJA, "      // Loja do fornecedor
       _cQry += " A2_NOME, "       // Nome do fornecedor
       _cQry += " A2_CGC "
       _cQry += " FROM "+RetSqlName("SD1")+ " SD1, " + RetSqlName("SA2") + " SA2, " + RetSqlName("SB1") + " SB1, "  + RetSqlName("SF1") + " SF1 " 
       _cQry += " WHERE SD1.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' AND SF1.D_E_L_E_T_ = ' ' "
       _cQry += " AND D1_TPREPAS = ' ' AND D1_FORNECE = A2_COD AND D1_LOJA  = A2_LOJA AND A2_TIPO = 'J' AND A2_CGC <> ' ' AND A2_DESPORT = '1' "      //AND (A2_DESPORT = ' ' OR A2_DESPORT = '0') "
       _cQry += " AND D1_FORNECE = F1_FORNECE AND D1_LOJA  = F1_LOJA AND D1_FILIAL = F1_FILIAL AND F1_DOC = D1_DOC AND F1_SERIE = D1_SERIE " 
       _cQry += " AND D1_VALINS > 0 AND D1_COD = B1_COD "
    
       If ! Empty(MV_PAR01) // Filial  
          _cQry +=  " AND D1_FILIAL IN " + FormatIn(MV_PAR01,";")
       EndIf

       If ! Empty(MV_PAR02) // Data de  
          _cQry += " AND D1_EMISSAO >= '"+DToS(MV_PAR02)+"' " // D1_DTDIGIT
       EndIf
   
       If ! Empty(MV_PAR03) // Data até 
          _cQry += " AND D1_EMISSAO <= '"+DToS(MV_PAR03)+"' " // D1_DTDIGIT
       EndIf

       If ! Empty(MV_PAR04) // Produto
          _cQry +=  " AND D1_COD IN " + FormatIn(MV_PAR04,";")
       EndIf	

   ElseIf _nQuery == 6 // 8  // RELATORIO H - R-2040 - Faturas (T154) 
      _cQry :=  "SELECT DISTINCT " 
      _cQry += " E2_FILIAL, "     // FILIAL  		   	
      _cQry += " E2_EMISSAO, "    // DATA EMISSAO 
      _cQry += " E2_NUM    ,  "   // NUM TITULO 
      _cQry += " E2_FORNECE,  "   // FORNECEDOR 
      _cQry += " E2_LOJA   ,  "   // LOJA
      _cQry += " E2_NOMFOR ,  "   // NOME FORNECEDOR
      _cQry += " E2_PREFIXO, "  
      _cQry += " E2_PARCELA, " 
      _cQry += " E2_TIPO   ,  " 
      _cQry += " FK7_CHAVE, 
      _cQry += " FK7_FILIAL, "  
      _cQry += " FK7_ALIAS, " 
      _cQry += " FKF_TPSERV, " 
      _cQry += " E2_BASEINS, "
      _cQry += " E2_INSS, "
      _cQry += " A2_CGC "
      _cQry += " FROM "+RetSqlName("SE2")+ " SE2, " + RetSqlName("FK7") + " FK7, " + RetSqlName("FKF") + " FKF, "+RetSqlName("SA2")+ " SA2 " 
      _cQry += " WHERE SE2.D_E_L_E_T_ = ' ' AND FK7.D_E_L_E_T_ = ' ' AND FKF.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' '  "
      _cQry += " AND E2_FILIAL   = FK7_FILTIT "
      _cQry += " AND E2_PREFIXO  = FK7_PREFIX "
      _cQry += " AND E2_NUM      = FK7_NUM "
      _cQry += " AND E2_PARCELA  = FK7_PARCEL "
      _cQry += " AND E2_TIPO     = FK7_TIPO "
      _cQry += " AND E2_FORNECE  = FK7_CLIFOR "
      _cQry += " AND E2_LOJA     = FK7_LOJA "
      _cQry += " AND E2_FILIAL = FK7_FILIAL AND FK7_ALIAS = 'SE2'  "
      _cQry += " AND E2_FORNECE = A2_COD AND E2_LOJA = A2_LOJA  "
      _cQry += " AND FK7_FILIAL = FKF_FILIAL AND FK7_IDDOC = FKF_IDDOC  "
      _cQry += " AND E2_INSS > 0  "
      _cQry += " AND E2_ORIGEM = 'FINA050' " // E2_TITPAI = ' ' 
      _cQry += " AND A2_TIPO = 'J'  "
      _cQry += " AND FKF_TPREPA <> ' ' "
      _cQry += " AND A2_DESPORT = '1' "

      If ! Empty(MV_PAR01) // Filial  
         _cQry +=  " AND E2_FILIAL IN " + FormatIn(MV_PAR01,";")
      EndIf

      If ! Empty(MV_PAR02) // Data de  
         _cQry += " AND E2_EMISSAO >= '"+DToS(MV_PAR02)+"' "
      EndIf
   
      If ! Empty(MV_PAR03) // Data até 
         _cQry += " AND E2_EMISSAO <= '"+DToS(MV_PAR03)+"' "
      EndIf

   ElseIf _nQuery == 7 // R-2055 - Aquisição Produtor Rural - Documentos Fiscais (T013)
      _cQry := " SELECT DISTINCT "
      _cQry += " D1_FILIAL, "    // FILIAL
      _cQry += " D1_DTDIGIT, "   // DATA DIGITAÇÃO 
      _cQry += " D1_EMISSAO, "   // DATA EMISSAO 
      _cQry += " F1_ESPECIE, "   // ESPECIE
      _cQry += " D1_DOC,    "    // NOTA FISCAL - 		
      _cQry += " D1_SERIE,  "    // SERIE
      _cQry += " D1_COD,    "    // PRODUTO
      _cQry += " D1_BASEINS, "   // BASE INSS 
      _cQry += " D1_ALIQINS, "   // ALIQUOTA 
      _cQry += " D1_VALINS, "    // VALOR INSS
      _cQry += " D1_CODISS, "    // OCORRENCIA
      _cQry += " D1_ALIQINS, "   // OCORRENCIA 
      _cQry += " B1_CODISS,  "   // OCORRENCIA 
      _cQry += " D1_CODISS,   "  // OCORRENCIA  
      _cQry += " B1_COD, "       // Codigo do produto.
      _cQry += " B1_DESC, "      // Codigo do produto.
      _cQry += " A2_COD, "       // Codigo do fornecedor
      _cQry += " A2_LOJA, "      // Loja do fornecedor
      _cQry += " A2_NOME, "      // Nome do fornecedor
      _cQry += " A2_CGC, "       // CNPJ do fornecedor
      _cQry += " A2_INDCP, "       // CNPJ do fornecedor // JPP TESTE
      _cQry += " D1_BSSENAR, "   // BASE SENAR
      _cQry += " D1_ALSENAR, "   // ALIQUOTA SENAR
      _cQry += " D1_VLSENAR, "   // VALOR SENAR
      _cQry += " D1_BASEFUN, "   // BASE FUNRURAL 
      _cQry += " D1_ALIQFUN, "   // ALIQUOTA FUNRURAL
      _cQry += " D1_VALFUN,  "   // VALOR FUNRURAL
      _cQry += " FT_INDISEN,  "  // Ind Isent Contr Previdenc
      _cQry += " D1_TES"         // TES  
      _cQry += " FROM "+RetSqlName("SD1")+ " SD1, " + RetSqlName("SA2") + " SA2, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SF1") + " SF1 , " + RetSqlName("SFT") + " SFT "   
      _cQry += " WHERE SD1.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' AND SF1.D_E_L_E_T_ = ' ' AND SFT.D_E_L_E_T_ = ' ' "
      _cQry += " AND D1_FORNECE = A2_COD AND D1_LOJA  = A2_LOJA AND A2_CGC <> ' ' "
      _cQry += " AND D1_FORNECE = F1_FORNECE AND D1_LOJA  = F1_LOJA AND D1_FILIAL = F1_FILIAL AND F1_DOC = D1_DOC AND F1_SERIE = D1_SERIE "
      _cQry += " AND D1_COD = B1_COD  "
      _cQry += " AND FT_FILIAL = D1_FILIAL AND FT_NFISCAL = D1_DOC AND FT_SERIE = D1_SERIE AND FT_CLIEFOR = D1_FORNECE AND FT_LOJA = D1_LOJA "
      _cQry += " AND FT_ITEM = D1_ITEM AND FT_PRODUTO = D1_COD "
      _cQry += " AND (A2_TIPORUR = 'F' OR A2_TIPORUR = 'L') "

      If ! Empty(MV_PAR01) // Filial  
         _cQry +=  " AND D1_FILIAL IN " + FormatIn(MV_PAR01,";")
      EndIf

      If ! Empty(MV_PAR02) // Data de  
      
         _cQry += " AND D1_EMISSAO >= '"+DToS(MV_PAR02)+"' " // D1_DTDIGIT
      EndIf
   
      If ! Empty(MV_PAR03) // Data até 
         _cQry += " AND D1_EMISSAO <= '"+DToS(MV_PAR03)+"' " // D1_DTDIGIT
      EndIf

      If ! Empty(MV_PAR04) // Produto
         _cQry +=  " AND D1_COD IN " + FormatIn(MV_PAR04,";")
      EndIf
   
   EndIf

End Sequence

Return _cQry												 

/*
===============================================================================================================================
Programa----------: RFIN016Q
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/07/2018
Descrição---------: Monta e retorna todas as querys utilizadas no relatório.
Parametros--------: _nQuery = numero da query.
Retorno-----------: _cQry = Query solicitada.
===============================================================================================================================
*/
User Function RFIN016L()

Local _lRet := .T.
 
Begin Sequence 
   
   // R-2070-Retenções na Fonte - IR, CSLL, Cofins, PIS/PASEP
   // Esta opção de relatório está aguardando liberação do governo para análie e lavantamento de dados.
   // Aguardando liberação de dados do governo para analise e desenvolvimento.
   
   If "R-2010" $ MV_PAR05 .Or. "R-2020" $ MV_PAR05 .Or. "R-2030" $ MV_PAR05 .Or. "R-2040" $ MV_PAR05 .Or. "R-2055" $ MV_PAR05  
      If "R-2070" $ MV_PAR05
         U_ITMsg("O relatório 'R-2070-Retenções na Fonte - IR, CSLL, Cofins, PIS/PASEP' não está disponível para emissão. Estamos aguardando liberação do governo para darmos inicio a análise e desenvolvimento.","Atenção", ,1) 
      EndIf
   ElseIf "R-2070" $ MV_PAR05
      U_ITMsg("O relatório 'R-2070-Retenções na Fonte - IR, CSLL, Cofins, PIS/PASEP' não está disponível para emissão. Estamos aguardando liberação do governo para darmos inicio a análise e desenvolvimento.","Atenção", ,1) 
      _lRet := .F.
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa----------: RFIN016K()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/05/2021
Descrição---------: Gera os dados e imprime o relatório.
                    R-2055 - Aquisição Produtor Rural - Documentos Fiscais (T013)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN016K()
Local _cQry 
Local _nTotRegs
Local _cOcorrencia
Local _cTexto

Begin Sequence
   _cQry := U_RFIN016Q(7)
   
   If Select("TRB_I") > 0
	  TRB_I->(DBCloseArea())
   EndIf
   
   TCQUERY _cQry NEW ALIAS "TRB_I"	
   
   TCSetField('TRB_I',"D1_DTDIGIT","D",8,0)
   TCSetField('TRB_I',"D1_EMISSAO","D",8,0)
   	
   DBSelectArea("TRB_I")
   TRB_I->(DBGoTop())

   Count to _nTotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   TRB_I->(DBGoTop())
   
   // Inicializando a seção _oSect0_I 
   _oSect0_I:Init()
   _oSect0_I:Cell("EVENTO"):SetValue("R-2055 - Documentos Fiscais (T013)")
   _oSect0_I:PrintLine()
   
   // Inicializando a seção _oSect1_I	 
   _oSect1_I:Init()

   _oReport:IncMeter()
   
   // Inicia processo de impressão.	
   While !TRB_I->(Eof())
		
      If _oReport:Cancel()
		   Exit
      EndIf
          
      // Valor INSS, Valor Senar, e Valor Funrural 
      If TRB_I->D1_VLSENAR == 0 .And. TRB_I->D1_VALINS == 0 .And. TRB_I->D1_VALFUN == 0
         TRB_I->(DBSkip())
         Loop
      EndIf     

      // Imprimindo a seção _oSect1_I 
      _oSect1_I:Cell("D1_FILIAL"):SetValue(TRB_I->D1_FILIAL)  
      _oSect1_I:Cell("D1_DTDIGIT"):SetValue(TRB_I->D1_DTDIGIT)	 
      _oSect1_I:Cell("D1_EMISSAO"):SetValue(TRB_I->D1_EMISSAO)  
      _oSect1_I:Cell("F1_ESPECIE"):SetValue(TRB_I->F1_ESPECIE)	 
      _oSect1_I:Cell("D1_DOC"):SetValue(TRB_I->D1_DOC) 
      _oSect1_I:Cell("D1_SERIE"):SetValue(TRB_I->D1_SERIE) 
      _oSect1_I:Cell("D1_COD"):SetValue(TRB_I->D1_COD) 
      _oSect1_I:Cell("D1_BASEINS"):SetValue(TRB_I->D1_BASEINS)  
      _oSect1_I:Cell("D1_ALIQINS"):SetValue(TRB_I->D1_ALIQINS)  
      _oSect1_I:Cell("D1_VALINS"):SetValue(TRB_I->D1_VALINS)  	

      _oSect1_I:Cell("A2_COD"):SetValue(TRB_I->A2_COD)    // Codigo do fornecedor 
      _oSect1_I:Cell("A2_LOJA"):SetValue(TRB_I->A2_LOJA)  // Loja do fornecedor  
      _oSect1_I:Cell("A2_NOME"):SetValue(TRB_I->A2_NOME)  // Nome do fornecedor     
      _oSect1_I:Cell("A2_CGC"):SetValue(TRB_I->A2_CGC)  

      _cTexto := ""
      If TRB_I->A2_INDCP == "1"
         _cTexto := "Sobre a Producao"
      ElseIf TRB_I->A2_INDCP == "2"
         _cTexto := "Sobre a Folha"
      ElseIf Empty(TRB_I->A2_INDCP)
         _cTexto := "Vazio"
      EndIf 
      _oSect1_I:Cell("A2_INDCP"):SetValue(_cTexto)  

      _oSect1_I:Cell("B1_DESC"):SetValue(TRB_I->B1_DESC)  // Descrição do produto. 

      _oSect1_I:Cell("D1_BSSENAR"):SetValue(TRB_I->D1_BSSENAR)	  // "BASE SENAR"     
      _oSect1_I:Cell("D1_ALSENAR"):SetValue(TRB_I->D1_ALSENAR)	  // "ALIQUOTA SENAR"   
      _oSect1_I:Cell("D1_VLSENAR"):SetValue(TRB_I->D1_VLSENAR)	  // "VALOR SENAR"      
      _oSect1_I:Cell("D1_BASEFUN"):SetValue(TRB_I->D1_BASEFUN)	  // "BASE FUNRURAL"   
      _oSect1_I:Cell("D1_ALIQFUN"):SetValue(TRB_I->D1_ALIQFUN)	  // "ALIQUOTA FUNRURAL"
      _oSect1_I:Cell("D1_VALFUN"):SetValue(TRB_I->D1_VALFUN)	  // "VALOR FUNRURAL"   

     _cOcorrencia := ""
     
     If TRB_I->D1_BSSENAR == 0 .And. TRB_I->D1_BASEINS == 0 .And. TRB_I->D1_BASEFUN == 0
        _cOcorrencia += " OC01 - PRODUTOR RURAL SEM CALCULO DE FUNRURAL. "
     EndIf 

     If TRB_I->FT_INDISEN <> "1" 
        _cOcorrencia += " OC02 - A nota "+ AllTrim(TRB_I->D1_DOC)+"-"+AllTrim(TRB_I->D1_SERIE) + " foi lançada na TES " + TRB_I->D1_TES  + " e o campo FT_INDISEN esta diferente de SIM. "
     EndIf 

     _oSect1_I:Cell("OCORRENCIA"):SetValue(_cOcorrencia)
     
     _oSect1_I:PrintLine()
 
     TRB_I->(DBSkip())
   EndDo   
   
   // Imprime linha separadora.
   _oReport:ThinLine()
 	
   // Finaliza primeira seção.	  
   _oSect1_I:Finish()
   
   // Finaliza seção Zero.	  
   _oSect0_I:Finish()

End Sequence

If Select("TRB_I") > 0
   TRB_I->(DBCloseArea())
EndIf

Return
