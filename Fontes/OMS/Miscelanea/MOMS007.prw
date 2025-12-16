#Include "TopConn.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MOMS007
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: EDI com clientes, le pedido de compra em aquivo .TXT e gera relatório para insercao do pedido de venda no   
                    sistema TOTVS.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS007()       

Private aArqs     := {}                          //Armzena o nome dos arquivos encontrados no diretorio especificado pelo usuario
Private cPath     := 'C:\NeoGrid\Pedidos\'       //Armazena o caminho do diretorio       

// Variaveis Private da Funcao
Private oDlg				// Dialog Principal
// Variaveis que definem a Acao do Formulario
Private VISUAL := .F.                        
Private INCLUI := .F.                        
Private ALTERA := .F.                        
Private DELETA := .F.                        

DEFINE MSDIALOG oDlg TITLE "IMPORTAÇÃO DE ARQUIVOS DE PEDIDO DE COMPRA" FROM C(318),C(454) TO C(525),C(990) PIXEL

	// Cria as Groups do Sistema
	@ C(003),C(004) TO C(063),C(264) LABEL "Informação" PIXEL OF oDlg

	// Cria Componentes Padroes do Sistema
	@ C(014),C(017) Say "Esta rotina ira efetuar a importação dos arquivos de pedidos de compra fornecidos pelos clientes para o sistema MICROSIGA gerando um relatório para inserção do pedido de venda para cada arquivo de pedido de compra do cliente, qualquer problema que ocorra nesta importação favor contactar o departamento de informática da ITALAC. É necessário que o usuário infomre o diretório onde os arquivos foram armazenados." Size C(233),C(038) COLOR CLR_BLACK PIXEL OF oDlg
	@ C(078),C(110) Button "Localização Arquivos" Size C(052),C(012) PIXEL OF oDlg ACTION(cPath:=tFileDialog("","SELECIONE O DIRETORIO ONDE SE ECONTRA OS PEDIDOS DO CLIENTE",,,.T.,GETF_LOCALHARD + GETF_RETDIRECTORY))
	@ C(078),C(173) Button "Cancelar" Size C(045),C(012) PIXEL OF oDlg ACTION( oDlg:End() )
	@ C(078),C(051) Button "Importar Pedidos" Size C(047),C(012) PIXEL OF oDlg ACTION(ImportaPed())

	// Cria ExecBlocks dos Componentes Padroes do Sistema

ACTIVATE MSDIALOG oDlg CENTERED 

Return(.T.)

/*
===============================================================================================================================
Programa----------: ImportaPed
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: REDI com carrefour, le pedido de compra do carrefour em aquivo .TXT e gera pedido de venda.
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ImportaPed()                                                   

If cPath == ""
	xMagHelpFis("INFORMAÇÃO",;
	"Favor informar o caminho onde se encontram os arquivo de pedido de compra de EDI.",;
	"A persistir o problema favor comunicar ao departamente de informática da ITALAC.")
	Return          
EndIf

oDlg:End()
            
//Funcao utilizada para pegar os arquivos .TXT no diretorio especificado pelo usuario
buscaArqTXT()   
     
//Caso nao encontre nenhum arquivo .TXT no diretorio especificado
If Len(aArqs) == 0

	xMagHelpFis("INFORMAÇÃO",;
	"Não existe nenhum arquivo .EDI no diretório informado.",;
	"Favor verificar a localização dos arquivos .EDI de pedido de compra, ao persistir o problema favor contactar o administrador do sistema.")
	Return                        
	
EndIf

//Funcao utilizada para gerar Pedido de venda a partir de arquivo do pedido de compra enviado pelo CARREFOUR.
Processa({|| RelImporta()},"Gerando relatorio de importacao. Favor Aguardar...")


Return

/*
===============================================================================================================================
Programa----------: buscaArqTXT
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: Funcao utilizada para ler todos os arquivos .TXT no diretorio especificado pelo usuario.
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function buscaArqTXT()

Local aArqOri   := {}
Local nXi		:= 0

aArqOri := directory(cPath + "*.EDI")
For nXi := 1 to Len(aArqOri)         
    //1 - Nome do arquivo,.F. nao foi lancado o pedido de compra anteriormente, 
    //2 - .T. ja havia sido lancado anteriormente o pedido,
    //3 - numero do pedido de venda,
    //4 - mensagem de erro,numero do pediddo de compra 	
    //5 - Numero do pedido de compra do cliente CARREFOUR
    //6 - Problema encontrado para realizar a geracao do pedido de venda
     aAdd(aArqs, {aArqOri[nXi, 1],.F.,"","","",.F.,.F.})
Next nXi

aArqs := aSort(aArqs) //Ordena Arquivos !!!

Return

/*
===============================================================================================================================
Programa----------: RelImporta
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: Funcao utilizada para gerar Pedido de venda a partir de arquivo do pedido de compra enviado pelo CARREFOUR.
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/     
Static Function RelImporta()

Local cLinhaAtual:= ""
Local cCodCliCom := ""
Local cCodLojaCl := ""
Local cDescClien := ""
Local cEndClient := ""
Local cMunClient := ""
Local cEstClient := ""
Local cCEPclient := ""
Local cCNPJClien := ""
Local cIECliente := ""
Local cNumPedCom := ""
Local nNumItem   := 0  
Local cQuery     := "" 
Local cCodProdut := ""
Local cUM        := ""  
Local cUM2       := ""
Local cUnMedidad := "" 
Local cqtdeUM    := ""
Local cqtdeUM2   := ""
Local nPrecoVend := "" 
Local nVlrTotLin := "" 
Local cDtEmissao := "" 
Local cDesProdut := "" 
Local cDtEntrega := "" 
Local cNroDoca   := "" 

Local cCnpjCliente := ""
Local cCodCliente  := ""
Local cLojCliente  := ""  
Local cCodEanCli   := "" 

Local nCountReg	   := 0
Local _lDun14      := "" 
Local cNomeArquivo := ""
Local _aProdSimilar := {}
Local _nI, _cUnCli, _nQtdCli, _nQtdNaEmb, _nQtdUnitItalac
Local _nPrecoItalac := 0 
Local nCont			:= 0

Private aCondPgto  := {}
Private aCabecPC   := {}
Private aItensPC   := {}

ProcRegua(Len(aArqs)) // Numero de registros a processar
          
//Percorre todos os arquivos de texto encontrados no diretorio especificado pelo usuario
For nCont:=1 to Len(aArqs)     

	IncProc("Processando o " + AllTrim(Str(nCont)) + "o. do " + AllTrim(Str(Len(aArqs))) + " pedido(s) de compra(s)." )
                                   
	FT_FUse(cPath + aArqs[nCont,1]) // Abre o arquivo
   
    cNomeArquivo := aArqs[nCont,1]
    	
	If FT_FLASTREC() == 0//Retorna a quantidade de linhas existentes no arquivo, caso nao exista itens no arquivo o retorno eh zero                           	
	   //xMagHelpFis("INFORMAÇÃO",;
       //"O arquivo " + cPath + aArqs[nCont,1] + " não possui dados contidos nele favor checar este arqiuvo.",;
       //"Contactar o departamento de informática informando de tal problema.")
	Else
       //Caso contratio percorre o arquivo para gerar o pedido de venda
       FT_FGOTOP()
	   While !FT_FEOF()                         
          //Pega o conteudo da linha atual do arquivo corrente
		  cLinhaAtual:= FT_FREADLN() 
          Do Case 			
             //Cabecalho(Uma unica ocorrencia)
			 Case SubStr(cLinhaAtual,1,2) == '01'   
			 
				  nNumItem := 0
                  //Busca dados do Comprador
				  DBSelectArea("SA1")
				  SA1->(dbOrderNickName("CODEAN")) //Filial + CNPJ
				  If SA1->(DBSeek(xFilial("SA1") + SubStr(cLinhaAtual,154,13)))
                     cCodCliCom:= SA1->A1_COD  			//Codigo do Cliente comprador
				 	 cCodLojaCl:= SA1->A1_LOJA 			//Loja do Cliente 
				 	 cDescClien:= AllTrim(SA1->A1_NOME)	//Descricao do Cliente
				 	 cEndClient:= AllTrim(SA1->A1_END)	//Endereco do Cliente
				 	 cMunClient:= AllTrim(SA1->A1_MUN)	//Municipio do Cliente
				 	 cEstClient:= SA1->A1_EST			//Estado do cliente
				 	 cCEPclient:= SA1->A1_CEP			//Cep do Cliente
				 	 cCNPJClien:= SA1->A1_CGC			//CNPJ do cliente
				 	 cIECliente:= SA1->A1_INSCR			//Inscricao Estadual do cliente	   
				 		
				 	 cNumPedCom:= SubStr(cLinhaAtual,09 ,20)//Armazena o numero do pedido do comprador
				 	 cDtEmissao:= SubStr(cLinhaAtual,49 ,12)//Data e Hora da Emissao do Pedido de compra
				 	 cDtEntrega:= SubStr(cLinhaAtual,61 ,12)//Data e Hora da Emissao do Pedido de compra 
				 	 cNroDoca  := SubStr(cLinhaAtual,273,02)//Numero da Doca  				 						 
				 		        				 			
					 /*
					 //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					 //³Nao foi encontrado o codigo EAN do cliente no cadastro de clientes³
					 //³do sistema TOTVS.                                                 ³
					 //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					 */
				  Else                                
                     cCodCliCom:= ""  									//Codigo do Cliente comprador
					 cCodLojaCl:= "" 									//Loja do Cliente 
					 cDescClien:= "Cliente sem codigo EAN cadastrado" 	//Descricao do Cliente
					 cEndClient:= ""										//Endereco do Cliente
					 cMunClient:= ""										//Municipio do Cliente
					 cEstClient:= ""										//Estado do cliente
					 cCEPclient:= ""										//Cep do Cliente
					 cCNPJClien:= ""										//CNPJ do cliente
					 cIECliente:= ""										//Inscricao Estadual do cliente	  
                     //Talita Teixeira - 14/08/14 - Inicio da alteração - Incluido o preenchimento das variaveis que trarão a informação do cnpj, cod e loja do cliente e cod ean no relatorio. Chamado: 7077
					 cCnpjCliente:= SubStr(cLinhaAtual,195,14)	 
				
					 				
					 DBSelectArea("SA1")
					 DBSetOrder(3)
					 DBSeek(xFilial("SA1")+cCnpjCliente)
							
				     cCodCliente:= SA1->A1_COD 
				     cLojCliente:= SA1->A1_LOJA
				     cCodEanCli:= SubStr(cLinhaAtual,154,13)   
				 			    
				 	 aArqs[nCont,2]:= .T.
				 	 aArqs[nCont,4]:= "Cliente sem codigo EAN cadastrado"
					 aArqs[nCont,5]:= SubStr(cLinhaAtual,09 ,20)//Armazena o numero do pedido do comprador
					 aArqs[nCont,6]:= .T.   
					 aArqs[nCont,7]:= .T.
							 	
					 cNumPedCom:= SubStr(cLinhaAtual,09 ,20)//Armazena o numero do pedido do comprador
				 	 cDtEmissao:= SubStr(cLinhaAtual,49 ,12)//Data e Hora da Emissao do Pedido de compra
				 	 cDtEntrega:= SubStr(cLinhaAtual,61 ,12)//Data e Hora da Emissao do Pedido de compra 
				 	 cNroDoca  := SubStr(cLinhaAtual,273,02)//Numero da Doca   
				 				  
				 	 SA1->(DBCloseArea()) 					 		
				  EndIf
				 	
				  //Pagamento(De zero a N ocorrencias)
		     Case SubStr(cLinhaAtual,1,2) == '02'  
		          aAdd(aCondPgto,{;
				                 cNumPedCom,;//Numero do pedido de compra
				 	             SubStr(cLinhaAtual,6,3),;//Referencia da Data
				 	             SubStr(cLinhaAtual,15,3),;//Numero de Periodos
				 	             SubStr(cLinhaAtual,18,8),;//Data de Vencimento
				 	             Val(SubStr(cLinhaAtual,26,15))/100,;//Valor a pagar
				 	             SubStr(cLinhaAtual,41,05);//Percentual a pagar do valor faturado 
				 	             })
				 	                                    
				  //Itens do pedido(De uma a N ocorrencias)
	         Case SubStr(cLinhaAtual,1,2) == '04'
			     //Incrementa o numero da linha do Item
			     ++nNumItem         
				_aProdSimilar := {}
				 		           
			    // Verifica se o código passado é DUN14 ou EAN13
                If Len(AllTrim(SubStr(cLinhaAtual,18,14))) == 14	// DUN14 possui 14 posições.			 		
			       _lDun14 := .T.
			    Else
			       _lDun14 := .F.
			    EndIf  
				 		
				//Selectiona o codigo do produto a partir do EAN do Produto
				cQuery := "SELECT"
				cQuery += " B1_COD,B1_DESC,B1_MSBLQL, B1_I_DUN14 "                                                  
				cQuery += "FROM "                              
				cQuery +=  RetSqlName("SB1") + " B1 "          
				cQuery += "WHERE"               
				cQuery += " D_E_L_E_T_ = ' ' "
				cQuery += " AND B1_FILIAL = '"  + xFilial("SB1") + "' AND B1_TIPO = 'PA' " 
  				//cQuery += " AND B1_I_CDEAN = '" + AllTrim(SubStr(cLinhaAtual,18,14)) + "'"
  				If _lDun14
  				   cQuery += " AND B1_I_DUN14 = '"+AllTrim(SubStr(cLinhaAtual,18,14))+"'"
  				Else
  				   cQuery += " AND (B1_CODBAR = '"+AllTrim(SubStr(cLinhaAtual,18,13))+"' OR B1_I_DUN14 = '"+AllTrim(SubStr(cLinhaAtual,18,13))+"') "       // + IIf(AllTrim(SubStr(cLinhaAtual,18,1))="0",AllTrim(SubStr(cLinhaAtual,19,13)),AllTrim(SubStr(cLinhaAtual,18,13))) + "'" //HEDER - 22/06/2011 - Modificado caso o preenchimento dos 14 digitos seja feito com um Zero '0' a esquerda//21/05/13 - Talita - Alterado o campo B1_I_CDEAN pelo B1_CODBAR. Conforme chamado 3361
  				EndIf
  						
  				cQuery += " AND B1_MSBLQL <> '1' " //Talita Teixeira - 21/08/14 - Incluido na query para que não traga os produtos bloqueados. Chamado: 7172						
  					  						                               
  				cQuery += " ORDER BY B1.B1_COD "
  				//Para que nao ocorra erro, quando duas pessoas acessarem o relatorio simultaneamente
    			If Select("TMPPROD") > 0 
    			   DBSelectArea("TMPPROD")
    		       TMPPROD->(DBCloseArea())
    			EndIf                   
    
				dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(cQuery))),'TMPPROD',.F.,.T.) 
				//Inicio da Alteração - Talita Teixeira - 21/08/14 - Incluida a validação para que só tiver produtos bloqueados apresente uma mensagem de erro informando que o produto está bloqueado. Chamado: 7172
				Count to  nCountReg     
						
				If nCountReg == 0
                   cQuery := "SELECT"
				   cQuery += " B1_COD,B1_DESC,B1_MSBLQL, B1_I_DUN14 "                                                  
				   cQuery += "FROM "                              
				   cQuery +=  RetSqlName("SB1") + " B1 "          
				   cQuery += "WHERE"               
				   cQuery += " D_E_L_E_T_ = ' ' "
				   cQuery += " AND B1_FILIAL = '"  + xFilial("SB1") + "' AND B1_TIPO = 'PA'" 
	  			   //cQuery += " AND B1_CODBAR = '" + IIf(AllTrim(SubStr(cLinhaAtual,18,1))="0",AllTrim(SubStr(cLinhaAtual,19,13)),AllTrim(SubStr(cLinhaAtual,18,13))) + "'" 
	  			   If _lDun14
  				      cQuery += " AND B1_I_DUN14 = '"+AllTrim(SubStr(cLinhaAtual,18,14))+"'"
  				   Else
  				      cQuery += " AND (B1_CODBAR = '"+AllTrim(SubStr(cLinhaAtual,18,13))+"' OR B1_I_DUN14 = '"+AllTrim(SubStr(cLinhaAtual,18,13))+"') " // + IIf(AllTrim(SubStr(cLinhaAtual,18,1))="0",AllTrim(SubStr(cLinhaAtual,19,13)),AllTrim(SubStr(cLinhaAtual,18,13))) + "'" //HEDER - 22/06/2011 - Modificado caso o preenchimento dos 14 digitos seja feito com um Zero '0' a esquerda//21/05/13 - Talita - Alterado o campo B1_I_CDEAN pelo B1_CODBAR. Conforme chamado 3361
  				   EndIf
  					         
        	       cQuery += " ORDER BY B1.B1_COD "  					         
        	       
	  			   If Select("TMPPROD") > 0 
	    		      DBSelectArea("TMPPROD")
	    			  TMPPROD->(DBCloseArea())
	    		   EndIf                   
	    
				   dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(cQuery))),'TMPPROD',.F.,.T.) 
  			    EndIf 
						
				DBSelectArea("TMPPROD")
				TMPPROD->(DBGoTop())   
						

				//Verifica se o produto possui amarracao com o cadastro de produtos
				If TMPPROD->(Eof())
                   If _lDun14  				      
  				      cCodProdut := AllTrim(SubStr(cLinhaAtual,18,14))                        
  				      cDesProdut:= "*** CODIGO DUN 14 SEM AMARRACAO NO CADASTRO ***" //Descricao do Produto 
  				   Else
  				      cCodProdut := AllTrim(SubStr(cLinhaAtual,18,13))
  				      cDesProdut:= "*** CODIGO EAN SEM AMARRACAO NO CADASTRO ***" //Descricao do Produto     
  				   EndIf	
			       aArqs[nCont,4]:= "***Produtos sem amarracao do codigo EAN***"
				   aArqs[nCont,5]:= cNumPedCom
				   aArqs[nCont,6]:= .T.  
		 		Else  
                   If TMPPROD->B1_MSBLQL <> '1'
                      cCodProdut:= TMPPROD->B1_COD            //Codigo do Produto
					  cDesProdut:= AllTrim(TMPPROD->B1_DESC) //Descricao do Produto    
				   Else 
                      //cCodProdut:= IIf(AllTrim(SubStr(cLinhaAtual,18,1))="0",AllTrim(SubStr(cLinhaAtual,19,13)),AllTrim(SubStr(cLinhaAtual,18,13)))     //Codigo do Produto //HEDER - 22/06/2011 - Modificado caso o preenchimento dos 14 digitos seja feito com um Zero '0' a esquerda
                      If _lDun14  				      
  				         cCodProdut := AllTrim(SubStr(cLinhaAtual,18,14))                        
  				      Else
  				         cCodProdut := AllTrim(SubStr(cLinhaAtual,18,13))
  				      EndIf
					  cDesProdut:= "***PRODUTO BLOQUEADO***" //Descricao do Produto     
							 	                    
					  aArqs[nCont,4]:= "Produto bloqueado para uso"
					  aArqs[nCont,5]:= cNumPedCom
					  aArqs[nCont,6]:= .T.  
				   EndIf	
				   
				   _aProdSimilar := {}
				   While !TMPPROD->(Eof()) 
				      If TMPPROD->B1_MSBLQL <> '1'
					     aAdd(_aProdSimilar,{TMPPROD->B1_COD,AllTrim(TMPPROD->B1_DESC)})
					  EndIf 
					  
					  If !Empty(TMPPROD->B1_I_DUN14)
					     _lDun14 := .T.                            
					  EndIf
					  
					  TMPPROD->(DBSkip())
				   EndDo
				EndIf 	   			
				//Fim da alteração. Chamado: 7172
					
				//Finaliza o arquivo temporario
				DBSelectArea("TMPPROD")
    			TMPPROD->(DBCloseArea())
    					            
    			//Unidade Medida Cliente
    			_cUnCli := SubStr(cLinhaAtual,92,03)
    			
    			//Unidade de Medida 
    			cUM:=SubStr(cLinhaAtual,92,03)
    			Do Case  
                   Case cUM == 'EA ' 
				        cUnMedidad:='UN'
				   Case cUM == 'GRM' 
				        cUnMedidad:= 'G'	
				   Case cUM == 'KGM' 
						cUnMedidad:= 'KG'
				   Case cUM == 'LTR' 
				        cUnMedidad:= 'L'
				   Case cUM == 'MTR' 
				        cUnMedidad:= 'MT'	
				   Case cUM == 'MTK' 
						cUnMedidad:= 'M2'
				   Case cUM == 'MTQ' 
				        cUnMedidad:= 'M3'
	   			   Case cUM == 'MLT'
				        cUnMedidad:= 'ML' 	
				   Case cUM == 'TNE' 
				        cUnMedidad:= 'TL'
				   Case cUM == 'PCE' 
				        cUnMedidad:= 'PC'								
				EndCase
    			
    			// Quantidade Cliente, sem conversão de unidade  	     
    			_nQtdCli := Val(SubStr(cLinhaAtual,100,13) + '.' + SubStr(cLinhaAtual,113,02))//Quantidade do item da linha do pedido de venda
    			
    			// Quantidades e unidades de medidas com conversão.		                                           					
    			DBSelectArea("SB1")	
    			SB1->(DBSetOrder(1))
    			SB1->(DBSeek(xFilial("SB1") + cCodProdut)) 
    			
    			// Um codigo DUN 14 é o código que representa a embalagem de embarque e por isso possui um digito a mais no código de barras.
    			// Exemplificando, um item unitário possui um código de barras de 13 digitos chamado EAN 13, a embalagem que agrupa mais de um item, a embalagem de embarque,
    			// possui um código de barras de 14 digitos denominado DUN 14. Sempre que um cliente envia um código de barras DUN 14, ele está se referindo a embalagem maior
    			// denominada no Protheus, como segunda unidade de medida, sendo assim, criamos a conversão DUN 14 abaixo.
    			If _lDun14
    			   cUnMedidad := SB1->B1_SEGUM // Por ser DUN 14 estamos trabalhando na segunda unidade de medida.
    			EndIf
    				
    			If AllTrim(cUnMedidad) == AllTrim(SB1->B1_SEGUM)                          	
                   cqtdeUM2:= Val(SubStr(cLinhaAtual,100,13) + '.' + SubStr(cLinhaAtual,113,02))//Quantidade do item da linha do pedido de venda   	     
    			   cqtdeUM := IIf(SB1->B1_TIPCONV == 'D',cqtdeUM2 * SB1->B1_CONV,cqtdeUM2 / SB1->B1_CONV)
    			   cUM	  := SB1->B1_UM  	
    			   cUM2	  := cUnMedidad                 
   			  	Else    
                   cqtdeUM := Val(SubStr(cLinhaAtual,100,13) + '.' + SubStr(cLinhaAtual,113,02))//Quantidade do item da linha do pedido de venda    				
                   cqtdeUM2:= IIf(SB1->B1_TIPCONV == 'D',cqtdeUM / SB1->B1_CONV,cqtdeUM * SB1->B1_CONV) 
                   cUM2	:= SB1->B1_SEGUM 	
                   cUM     := cUnMedidad
    			EndIf 
    					
    			nPrecoVend:=Val(SubStr(cLinhaAtual,183,13) + '.' + SubStr(cLinhaAtual,196,2) + '00')//Preco de venda do tem corrente
    			nVlrTotLin:=Val(SubStr(cLinhaAtual,168,15))/100 //Valor total da Linha  
    			_nQtdNaEmb := Val(SubStr(cLinhaAtual,95,5)) // Quantidade na embalagem - Cliente  
    			
    			If _nQtdNaEmb == 0                                         
    			   _nQtdUnitItalac := cqtdeUM                // Quantidade unitaria - Italac
                   If _lDun14    
                   	   If SB1->B1_I_QT3UM > 0
                           _nPrecoItalac :=  (nPrecoVend / SB1->B1_I_QT3UM) // Preço Italac calc pela 3a UM
                   	   Else
                           _nPrecoItalac := IIf(SB1->B1_TIPCONV == 'D',nPrecoVend / SB1->B1_CONV, nPrecoVend * SB1->B1_CONV) // Preço Italac
                      EndIf
                   Else
                      _nPrecoItalac := nPrecoVend
                   EndIf
                Else
                   _nQtdUnitItalac := _nQtdCli * _nQtdNaEmb    // Quantidade unitaria - Italac
                   _nPrecoItalac   := nPrecoVend / _nQtdNaEmb  // Preço Italac
                   cqtdeUM2        := IIf(SB1->B1_TIPCONV == 'D',_nQtdUnitItalac / SB1->B1_CONV, _nQtdUnitItalac * SB1->B1_CONV) // Preço Italac
				EndIf
				 	
				aAdd(aItensPC,  { ;        
								cNumPedCom,;			//Numero do Pedido de compra do Cliente CARREFOUR    1
								StrZero(nNumItem,2),;   //Numero do Item da linha do produto                 2
								cCodProdut,;			//Codigo do Produto Microsiga                        3
								cUM       ,;			//Primeira Unidade de Medida                         4
								cqtdeUM   ,;			//Quantidade primeira Unidade de Medida              5
								cUM2      ,;			//Segunda Unidade de Medida                          6
								cqtdeUM2  ,;			//Quantidade segunda Unidade de Medida               7
								nPrecoVend,;			//Preco de Venda                                     8
								nVlrTotLin,;			//Valor total da linha do item                       9
								cDesProdut,;            //Descricao do Produto                               10
								_cUnCli   ,;            //Unidade de medida do cliente                       11
								_nQtdCli  ,;            //Quantidade do cliente                              12
								"PRINCIPAL",;           //Informa se é item principal ou item similar        13
								_nQtdNaEmb,;            // Quantidade na embalagem - Cliente                 14
                                _nQtdUnitItalac,;       // Quantidade unitaria - Italac                      15
                                _nPrecoItalac,;         // Preço Italac                                      16
                                cNomeArquivo})          // Nome Arquivo                                      17
                                
				If Len(_aProdSimilar) > 1
				   For _nI := 1 To Len(_aProdSimilar)
				       If AllTrim(cCodProdut) <> AllTrim(_aProdSimilar[_nI,1])
				          aAdd(aItensPC,  { ;        
								       cNumPedCom,;			  //Numero do Pedido de compra do Cliente CARREFOUR   1
								       StrZero(nNumItem,2),;  //Numero do Item da linha do produto                2
								       _aProdSimilar[_nI,1],; //Codigo do Produto Microsiga                       3
								       "",;			          //Primeira Unidade de Medida                        4
								       0,;			          //Quantidade primeira Unidade de Medida             5
								       "",;			          //Segunda Unidade de Medida                         6
								       "",;			          //Quantidade segunda Unidade de Medida              7
								       0,;			          //Preco de Venda                                    8
								       0,;			          //Valor total da linha do item                      9
								       _aProdSimilar[_nI,2],; //Descricao do Produto                              10
								       "",;                   //Unidade de medida do cliente                      11
								       0,;                    //Quantidade do cliente                             12
								       "SIMILAR",;            //Informa se é item principal ou item similar       13
								       0,;                    // Quantidade na embalagem - Cliente                14
                                       0,;                    // Quantidade unitaria - Italac                     15
                                       0,;                    // Preço Italac                                     16
                                       ""})                   // Nome do Arquivo                                  17
								                                     
				       EndIf
				   Next
				EndIf
		  EndCase                        
	    
	      FT_FSKIP()
	   EndDo                    
	      				       
	   aAdd(aCabecPC,{;
	           cNumPedCom,;  //Numero do Pedido de compra do cliente CARREFOUR
			   cCodCliCom,;  //Codigo do Cliente
			   cCodLojaCl,;  //Loja do Cliente
			   cDescClien,;  //Descricao do Cliente
			   cEndClient,;  //Endereco do Cliente
			   cMunClient,;  //Municipio do Cliente
			   cEstClient,;  //Estado do Cliente
			   cCEPclient,;  //CEP do Cliente
			   cCNPJClien,;  //CNPJ do Cliente
			   cIECliente,;   //I.E. do Cliente
			   cDtEmissao,;    //Data e hora da emissao do pedido de compra CARREFOUR
			   cDtEntrega,;     //Data de Entrega  
			   cNroDoca,;        //Numero da Doca
			   cCnpjCliente,;    //CNPJ Cliente   - Talita Teixeira - 14/08/14 - Incluida no array as informações do cnpj, cod e loja do cliente e cod do ean para que sejam impressas no relatorio. Chamado: 7077
			   cCodCliente,;     //Codigo Cliente
			   cLojCliente,;     //Loja Cliente
			   cCodEanCli,;       //Codigo EAN
			   cNomeArquivo;     //Nome do Arquivo
			   })          
	EndIf				      
		
	FT_FUSE()//Fecha o arquivo
			 
Next nCont	
             					       
imprimeRel()

//Funcao responsavel por Renomear os arquivos *.edi para *.bkp
RenArquivos()	

Return  

/*
===============================================================================================================================
Programa----------: imprimeRel
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: Funcao utilizada para gerar Cabec parte 1 do Relatório.
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/     
Static Function imprimeRel()                          

Private cPerg  := "ROMS012"  

Private oFont12
Private oFont12b  
Private oFont16b           
Private oFont14
Private oFont14b

Private oPrint

Private nPagina     := 1

Private nLinha      := 0100  
Private nLinhaInic  := 0100  
Private nColInic    := 0030
Private nColFinal   := 3360  
Private nLinInBox   
Private nSaltoLinha := 50      

Private contrCor    := 1
Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)

Define Font oFont12    Name "Courier New"       Size 0,-10 Bold  // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
Define Font oFont14    Name "Courier New"       Size 0,-12       // Tamanho 14
Define Font oFont14b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 14 Negrito  
Define Font oFont16    Name "Courier New"       Size 0,-14       // Tamanho 16  //Talita Teixeira - 14/08/14  -  Incluido a fonte 16 para incluir na mensagem incluida no relatorio.
Define Font oFont16b   Name "Courier New"       Size 0,-14 Bold  // Tamanho 16 Negrito  
                         
//Caso tenha pedidos importados
If Len(aCabecPC) > 0  

	oPrint:= TMSPrinter():New("IMPORTACAO EDI PEDIDO DE COMPRA")
	oPrint:SetLandscape() 	// Paisagem
	oPrint:SetPaperSize(9)	// Seta para papel A4 
	oPrint:StartPage()		//Inicia uma nova Pagina					
	//oPrint:Setup()                             

EndIf

nLinha:=0100       
		
Processa({|| relDadoImp() })			

oPrint:Preview()	// Visualiza antes de Imprimir.


Return

/*
===============================================================================================================================
Programa----------: relDadoImp
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: Funcao utilizada para gerar Cabec parte 2 do Relatório.
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/         
Static Function relDadoImp() 

Local cCodItensP:= ""    
Local nTotQtde  := 0
Local nTotVlrTot:= 0     
Local cReferDat := "" 
Local nCont1	:= 0
Local nCont2	:= 0
Local nCont3	:= 0

//Pedidos de comra - Cabecalho
For nCont1:=1 to Len(aCabecPC)     

   nTotQtde  := 0
   nTotVlrTot:= 0
                   
   cCodItensP:= ""  
   nPagina   := 1              
   
   //Chama funcao para impressao de cabecalho
   Cabec(aCabecPC,nCont1)                                                                                                        
	                                                 
	//Condicao de pagamento                                       
	For nCont2:=1 to Len(aCondPgto)
	
		//Verifica se eh o mesmo pedido de compra
		If aCabecPC[nCont1,1] == aCondPgto[nCont2,1]   
		
			Do Case
					Case AllTrim(aCondPgto[nCont2,2]) == '1'
						cReferDat:='Data do Pedido' 
					Case AllTrim(aCondPgto[nCont2,2]) == '3' 
						cReferDat:='Data do Contrato'
					Case AllTrim(aCondPgto[nCont2,2]) == '5' 
						cReferDat:='Data da Fatura'
					Case AllTrim(aCondPgto[nCont2,2]) == '9' 
						cReferDat:='Data de Recebimento da Fatura'
					Case AllTrim(aCondPgto[nCont2,2]) == '21'   
						cReferDat:='Data de Recebimento da Mercadoria pelo Comprador'
					Case AllTrim(aCondPgto[nCont2,2]) == '66'   
						cReferDat:='Data Especificada no campo data de vencimento'
					Case AllTrim(aCondPgto[nCont2,2]) == '81'   
						cReferDat:='Data do embarque conforme documentos de transporte'
		    EndCase                   
		    
		    //Quebra de pagina
			If nLinha > 2345
				 
				oPrint:EndPage()		// Finaliza a Pagina.
				oPrint:StartPage()		//Inicia uma nova Pagina					
				nPagina++ 
				nLinha:= 0100
				Cabec(aCabecPC,nCont1)
						
			EndIf             
		    
		    oPrint:Say (nlinha,nColInic,'REFERÊNCIA DE PAGAMENTO: ' + cReferDat,oFont12b)
			nlinha+=nSaltoLinha   
		    //oPrint:Say (nlinha,nColInic,'DIAS DE PRAZO: ' + aCondPgto[nCont2,3],oFont12b)
			//nlinha+=nSaltoLinha         
			oPrint:Say (nlinha,nColInic,'DATA DE VENCIMENTO: ' + DToC(SToD(aCondPgto[nCont2,4])),oFont12b)
			nlinha+=nSaltoLinha   
			oPrint:Say (nlinha,nColInic,'VALOR A PAGAR:  ' + AllTrim(Transform(aCondPgto[nCont2,5],"999,999,999,999.99")),oFont12b)
			nlinha+=nSaltoLinha     
			oPrint:Say (nlinha,nColInic,'PERCENTUAL DA PARCELA COM RELAÇÃO AO VALOR TOTAL DA PEDIDO DE COMPRA:  ' + Transform(Val(aCondPgto[nCont2,6]),"999,99") + ' %',oFont12b)
			nlinha+=nSaltoLinha                                                                               
			nlinha+=nSaltoLinha    
			nlinha+=nSaltoLinha    
		    
		EndIf
	
	Next nCont2
    
    //Itens do pedido de compra                                     
	For nCont3:=1 to Len(aItensPC)
	    
		//Verifica se eh o mesmo pedido de compra
		If aCabecPC[nCont1,1] == aItensPC[nCont3,1] 
				
				nTotQtde  += aItensPC[nCont3,5]
				nTotVlrTot+= aItensPC[nCont3,9]
		
		    	//Verifica se eh necessaria a criacao de novo cabecalho dos itens do pedido de compra
		    	If cCodItensP <> aCabecPC[nCont1,1]
		    		
		    		cCodItensP:= aCabecPC[nCont1,1]    
		    		
		    			
					//Quebra de pagina
					If nLinha > 2345
				 
						oPrint:EndPage()					// Finaliza a Pagina.
						oPrint:StartPage()					//Inicia uma nova Pagina					
						nPagina++ 
						nLinha:= 0100    
						Cabec(aCabecPC,nCont1)
						
					EndIf                              
		    		
		    		//Imprime Cabecalho
		    		oPrint:Say (nlinha,nColInic,'ITEM',oFont12b)
		    		oPrint:Say (nlinha,nColInic + 110,'PRODUTO',oFont12b)    
		    		oPrint:Say (nlinha,nColInic + 480,'DESCRIÇÃO',oFont12b)  
		    		oPrint:Say (nlinha,nColInic + 1470,'QTDE NA',oFont12b)  
		    		oPrint:Say (nlinha,nColInic + 1780,'QTDE ',oFont12b)         // 1830
		    		oPrint:Say (nlinha,nColInic + 2055,'PRECO',oFont12b)         // 2125
		    		oPrint:Say (nlinha,nColInic + 2260,'QTDE UNIT',oFont12b)     // 2400
                    oPrint:Say (nlinha,nColInic + 2500,'QTDE EMB',oFont12b)     // 2400		    		
		    		oPrint:Say (nlinha,nColInic + 2810,'PRECO',oFont12b) 
                    oPrint:Say (nlinha,nColInic + 3105,'VALOR TOTAL',oFont12b)  
                    nlinha+=nSaltoLinha
                    oPrint:Say (nlinha,nColInic + 1495,'EMB.',oFont12b) 
                    oPrint:Say (nlinha,nColInic + 1780,'PEDIDA',oFont12b)  // 1830
                    oPrint:Say (nlinha,nColInic + 2300,'ITALAC',oFont12b)  // 2400
                    oPrint:Say (nlinha,nColInic + 2500,'ITALAC',oFont12b)  // 2400
                    oPrint:Say (nlinha,nColInic + 2805,'ITALAC',oFont12b)  // 2805
		    		nlinha+=nSaltoLinha     
		    		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
		    		
		    		//IMPRIME DADOS DO PRIMEIRO REGISTRO
		    		oPrint:Say (nlinha,nColInic,aItensPC[nCont3,2] ,oFont12b)       			 //ITEM
		    		oPrint:Say (nlinha,nColInic + 110,aItensPC[nCont3,3],oFont12b)  			 //PRODUTO   
 		    		oPrint:Say (nlinha,nColInic + 480,SubStr(aItensPC[nCont3,10],1,60),oFont12b) //DESCRICAO DO PRODUTO 		    		
		    		If aItensPC[nCont3,13] = "PRINCIPAL" // Impressão do item principal
					   oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
		    		   oPrint:Say (nlinha,nColInic + 1450,Transform(aItensPC[nCont3,14],"@E 999,99"),oFont12b)             //QUANTIDADE NA EMBALAGEM 
		    		   oPrint:Say (nlinha,nColInic + 1700,Transform(aItensPC[nCont3,12],"@E 999,999.99"),oFont12b)         //QUANTIDADE PEDIDA           // 1750
		    		   oPrint:Say (nlinha,nColInic + 1980,Transform(aItensPC[nCont3,8] ,"@E 99,999.99") ,oFont12b)         //PREÇO CLIENTE               // 2050
		    		   oPrint:Say (nlinha,nColInic + 2240,Transform(aItensPC[nCont3,15],"@E 999,999.99") ,oFont12b)        //QUANTIDADE UNITARIA ITALAC  // 2380  
		    		   oPrint:Say (nlinha,nColInic + 2460,Transform(aItensPC[nCont3,7],"@E 999,999.99") ,oFont12b)         //QUANTIDADE 2 UNIDAD ITALAC  
		    		   oPrint:Say (nlinha,nColInic + 2770,Transform(aItensPC[nCont3,16],"@E 9,999.9999") ,oFont12b)        //PRECO ITALAC
		    		   oPrint:Say (nlinha,nColInic + 3100,Transform(aItensPC[nCont3,9] ,"@E 999,999.99") ,oFont12b)        //VALOR TOTAL DA LINHA
     	    	    EndIf
     	    		nlinha+=nSaltoLinha    
		    		
		    		Else   
		    		
		    			//Quebra de pagina
						If nLinha > 2345
				 
							oPrint:EndPage()					// Finaliza a Pagina.
							oPrint:StartPage()					//Inicia uma nova Pagina					
							nPagina++ 
							nLinha:= 0100
							Cabec(aCabecPC,nCont1)
							
							//Imprime Cabecalho
				    		oPrint:Say (nlinha,nColInic,'ITEM',oFont12b)
		    		        oPrint:Say (nlinha,nColInic + 110,'PRODUTO',oFont12b)    
		    		        oPrint:Say (nlinha,nColInic + 480,'DESCRIÇÃO',oFont12b)  
		    		        oPrint:Say (nlinha,nColInic + 1470,'QTDE NA',oFont12b)  
		    		        oPrint:Say (nlinha,nColInic + 1780,'QTDE ',oFont12b)     // 1830
		    		        oPrint:Say (nlinha,nColInic + 2055,'PRECO',oFont12b)     // 2125
		    		        oPrint:Say (nlinha,nColInic + 2260,'QTDE UNIT',oFont12b) // 2400
		    		        oPrint:Say (nlinha,nColInic + 2500,'QTDE EMB',oFont12b) // 2400 
		    		        oPrint:Say (nlinha,nColInic + 2810,'PRECO',oFont12b) 
                            oPrint:Say (nlinha,nColInic + 3105,'VALOR TOTAL',oFont12b)  
                            nlinha+=nSaltoLinha
                            oPrint:Say (nlinha,nColInic + 1495,'EMB.',oFont12b) 
                            oPrint:Say (nlinha,nColInic + 1780,'PEDIDA',oFont12b)   // 1830
                            oPrint:Say (nlinha,nColInic + 2260,'ITALAC',oFont12b)   // 2400
                            oPrint:Say (nlinha,nColInic + 2500,'ITALAC',oFont12b)   // 2400
                            oPrint:Say (nlinha,nColInic + 2805,'ITALAC',oFont12b)   // 2805
				    		nlinha+=nSaltoLinha     
				    		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)                      
       					EndIf          
		    		
		    		//Imprime os demais Itens   
		    		oPrint:Say (nlinha,nColInic,aItensPC[nCont3,2] ,oFont12b)       									//ITEM
		    		oPrint:Say (nlinha,nColInic + 110,aItensPC[nCont3,3],oFont12b)  									//PRODUTO   
		    		oPrint:Say (nlinha,nColInic + 480,SubStr(aItensPC[nCont3,10],1,60),oFont12b) 						//DESCRICAO DO PRODUTO   
		    		If aItensPC[nCont3,13] = "PRINCIPAL" // Impressão do item principal
					   oPrint:Line(nLinha,nColInic,nLinha,nColFinal)	
		    		   oPrint:Say (nlinha,nColInic + 1450,Transform(aItensPC[nCont3,14],"@E 999,99"),oFont12b)             //QUANTIDADE NA EMBALAGEM 
		    		   oPrint:Say (nlinha,nColInic + 1700,Transform(aItensPC[nCont3,12],"@E 999,999.99"),oFont12b)         //QUANTIDADE PEDIDA           // 1750
		    		   oPrint:Say (nlinha,nColInic + 1980,Transform(aItensPC[nCont3,8] ,"@E 99,999.99") ,oFont12b)         //PREÇO CLIENTE               // 2050
		    		   oPrint:Say (nlinha,nColInic + 2240,Transform(aItensPC[nCont3,15],"@E 999,999.99") ,oFont12b)        //QUANTIDADE UNITARIA ITALAC  // 2380
		    		   oPrint:Say (nlinha,nColInic + 2460,Transform(aItensPC[nCont3,7],"@E 999,999.99") ,oFont12b)         //QUANTIDADE 2 UNIDAD ITALAC  
		    		   oPrint:Say (nlinha,nColInic + 2770,Transform(aItensPC[nCont3,16],"@E 9,999.9999") ,oFont12b)        //PRECO ITALAC
		    		   oPrint:Say (nlinha,nColInic + 3100,Transform(aItensPC[nCont3,9] ,"@E 999,999.99") ,oFont12b)        //VALOR TOTAL DA LINHA
     	    	    EndIf
		    		
     	    		nlinha+=nSaltoLinha    
		    	
		    	EndIf
	    	
		EndIf
	Next nCont3            
	
	//Imprime Totalizadores  
	nlinha+=nSaltoLinha  
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)        
	oPrint:Say (nlinha,nColInic,'TOTAIS',oFont12b) 	//QUANTIDADE 1a UM 
	//oPrint:Say (nlinha,nColInic + 1640,Transform(nTotQtde  ,"999,999,999,999.99"),oFont12b) 	//QUANTIDADE 1a UM                
	oPrint:Say (nlinha,nColInic + 2955,Transform(nTotVlrTot,"999,999,999,999.99"),oFont12b)   	//VALOR TOTAL DA LINHA     
	
	//Talita Teixeira - 14/08/2014 - Incluida a informação para os pedidos que não encontram o código do cliente para que seja impressa a informação de CNPJ, Cod, loja e Cod Ean para que seja solicitado a atualizaçaõ do cadastro pelo departamento responsavel. Chamado: 7077
	//Inicio da alteração
	If aArqs[nCont1][7] == .T.
	
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha
		nlinha+=nSaltoLinha
		nlinha+=nSaltoLinha
		nlinha+=nSaltoLinha
		
		oPrint:Say (nLinha,nColInic,"Código Ean do cliente não cadastrado. Favor solicitar o cadastro ao depto responsável. "	,oFont16b) 
		
		nlinha+=nSaltoLinha 
		oPrint:Say (nLinha,nColInic,"Dados do Cliente: ",oFont16b) 
		
		nlinha+=nSaltoLinha 
		oPrint:Say (nLinha,nColInic,"CNPJ: " +  Transform(aCabecPC[nCont1][14],"@R! NN.NNN.NNN/NNNN-99")	,oFont16) 
		
		nlinha+=nSaltoLinha
		oPrint:Say (nLinha,nColInic,"Código/Loja: " + aCabecPC[nCont1][15] + " - " + aCabecPC[nCont1][16]	,oFont16) 
		 
		nlinha+=nSaltoLinha
		oPrint:Say (nLinha,nColInic,"Código EAN: " + aCabecPC[nCont1][17]	,oFont16) 
		
		nlinha+=nSaltoLinha
   
	EndIf
    //Fim da alteração       
			         
	If nCont1 <> Len(aCabecPC)  
		//Inicia uma nova pagina
		oPrint:EndPage()					// Finaliza a Pagina.
		oPrint:StartPage()					//Inicia uma nova Pagina					
		nPagina:= 1                         //Seta a variavel de controle de numeracao
		nlinha := 0100
		
	EndIf
	
Next nCont1	    

//Imprime se houve algum problema com os arquivos fornecidos pelo CARREFOUR
VldPedComp()   
imprImport()

Return

Static Function Cabec(aCabecPC,nCont1)

Local cRaizServer := If(issrvunix(), "/", "\")                                                    
             
	//Codigo + loja + descricao do cliente
	oPrint:Say (nlinha,nColInic,aCabecPC[nCont1,2] + '/' + aCabecPC[nCont1,3] + ' - ' + aCabecPC[nCont1,4],oFont12b)
	oPrint:Say (nlinha,nColInic + 2000,'CONFIRMAÇÃO DO PEDIDO',oFont12b)      
	oPrint:Say (nlinha,nColInic + 3000,'PÁGINA: ' + Str(nPagina,3),oFont12b)
	nlinha+=nSaltoLinha 
    //Endereco do cliente                                                                                                                  
 	oPrint:Say (nlinha,nColInic,aCabecPC[nCont1,5],oFont12b)      
 	//DATA E HORA DE EMISSOAO DO PEDIDO DE COMRA PELO CARREFOUR
	oPrint:Say (nlinha,nColInic + 2000,'EMISSÃO : ' + DtoC(StoD(SubStr(aCabecPC[nCont1,11],1,8))) + '   ' + SubStr(aCabecPC[nCont1,11],9,2) + ':' + SubStr(aCabecPC[nCont1,11],11,2) + IIf(Len(AllTrim(aCabecPC[nCont1,13])) > 0,"   Nro.Doca: " + aCabecPC[nCont1,13],""  + '      Arq:' + aCabecPC[nCont1,18]),oFont12b)
	nlinha+=nSaltoLinha 
	//CEP + MUNICIPIO + ESTADO
	oPrint:Say (nlinha,nColInic,transform(aCabecPC[nCont1,8],"@R 99.999-999") + ' - ' + aCabecPC[nCont1,6] + '/' + aCabecPC[nCont1,7],oFont12b)
	//DATA E HORA DE EMISSOAO DO PEDIDO DE COMRA PELO CARREFOUR
	oPrint:Say (nlinha,nColInic + 2000,'DATA DE ENTREGA : ' + DToC(SToD(SubStr(aCabecPC[nCont1,12],1,8))) + '   ' + SubStr(aCabecPC[nCont1,12],9,2) + ':' + SubStr(aCabecPC[nCont1,11],11,2),oFont12b)
	oPrint:SayBitmap(nLinha,nColInic + 3000,cRaizServer + "system/lgrl01.bmp",250,100)  
	nlinha+=nSaltoLinha    
	//CNPJ + I.E.
	oPrint:Say (nlinha,nColInic,'CNPJ: ' + Transform(aCabecPC[nCont1,9],"@R! NN.NNN.NNN/NNNN-99") + '          I.E.: ' + aCabecPC[nCont1,10],oFont12b)
	oPrint:Say (nlinha,nColInic + 2000,'NUMERO DO PEDIDO : ' + aCabecPC[nCont1,1],oFont12b)	
	nlinha+=nSaltoLinha       
	oPrint:Box(nLinhaInic,nColInic,nlinha,nColFinal)
	oPrint:Line(nLinhaInic,1980,nlinha,1980)//Litragem 
	nlinha+=nSaltoLinha    
	nlinha+=nSaltoLinha    

Return
      
/*
===============================================================================================================================
Programa----------: VldPedComp
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: Funcao utilizada para Vlr Pedido de Compra do Cliente
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/     
Static Function VldPedComp()

Local cLinhaAtual:= "" 
Local cQuery     := ""      
Local nCountRec  := 0      
Local nLayout01  := .F.//Variavel que controla se o layout do arquivo esta dentro do padrao neogrid, se contem os registros obrigatorios - 01 - 02 - 09
Local nLayout04  := .F.
Local nLayout09  := .F.
Local nCont		:= 0

For nCont:=1 to Len(aArqs)
                                                        
	nLayout01    := .F.
	nLayout04    := .F.
	nLayout09    := .F.
	
	FT_FUse(cPath + aArqs[nCont,1]) // Abre o arquivo	
	
	If FT_FLASTREC() == 0//Retorna a quantidade de linhas existentes no arquivo, caso nao exista itens no arquivo o retorno eh zero                           
		
		aArqs[nCont,2]:=.T.
		aArqs[nCont,4]:="Arquivo nao possui dados contidos"  
		aArqs[nCont,6]:= .T.      
		
		nLayout01    := .T.
		nLayout04    := .T.
		nLayout09    := .T.
		
		Else
		    //Caso contrario percorre o arquivo para gerar o pedido de venda
			FT_FGOTOP()
			While !FT_FEOF()
			                              
				//Pega o conteudo da linha atual do arquivo corrente
				cLinhaAtual:= FT_FREADLN()  
				
				//Cabecalho(Uma unica ocorrencia)
				If SubStr(cLinhaAtual,1,2) == '01'     
				                
						nLayout01:= .T.
						
						//Armazena o numero do pedido de compra do cliente CARREFOUR
						aArqs[nCont,5]:= SubStr(cLinhaAtual,09,20)
						
				    	
				    	//Verifica se o pedido de compra ja foi lancado anteriormente
						cQuery := "SELECT"
						cQuery += " C6_NUM "                                                  
						cQuery += "FROM "                              
						cQuery +=  RetSqlName("SC6") + " C6 "          
						cQuery += "WHERE"               
						cQuery += " D_E_L_E_T_ = ' ' "
						cQuery += " AND C6_FILIAL = '"  + xFilial("SC6") + "'" 
  						cQuery += " AND C6_PEDCLI = '"  + SubStr(cLinhaAtual,09,20) + "'"
  						
  						//Para que nao ocorra erro, quando duas pessoas acessarem o relatorio simultaneamente
    					If Select("TMPPED") > 0 
    						DBSelectArea("TMPPED")
    						TMPPED->(DBCloseArea())
    					EndIf         
    					
    					dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(cQuery))),'TMPPED',.F.,.T.)   
						COUNT TO nCountRec	

						DBSelectArea("TMPPED")   
						TMPPED->(DBGoTop())          
						
						//Ja existia um pedido de venda lancado anteriormente
						If nCountRec > 0
						
							aArqs[nCont,2]:= .T.
							aArqs[nCont,3]:= TMPPED->C6_NUM
							aArqs[nCont,4]:= "Ped.de compra ja havia sido lançado" 
							aArqs[nCont,6]:= .T.
						
						EndIf      
						
						DBSelectArea("TMPPED")
    					TMPPED->(DBCloseArea())
				
				EndIf                           
				
				If SubStr(cLinhaAtual,1,2) == '04'    
					nLayout04:= .T.
				EndIf 
				
				If SubStr(cLinhaAtual,1,2) == '09'    
					nLayout09:= .T.
				EndIf   
			
			FT_FSKIP()
			EndDo
	 EndIf		             
	
	//O arquivo corrente nao esta dentro do padrao Neogrid Versao 3.0 
	If !nLayout01 .Or. !nLayout04 .Or. !nLayout09 
		aArqs[nCont,2]:= .T.
		aArqs[nCont,4]:= "Arquivo nao esta no padrao Neogrid"
		aArqs[nCont,6]:= .T.
	EndIf 
	                              
	FT_FUSE()//Fecha o arquivo

Next nCont

Return

/*
===============================================================================================================================
Programa----------: imprImport
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: Funcao utilizada visualizar o resultado do processamento da importacao.
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/     
Static Function imprImport()                   

Local   cNumItem    := 1
Local nCont			:= 0
Private nLinhaInic  := 0100
Private nLinha      := 0100
Private nColInic    := 0030
Private nColFinal   := 2360  
Private nSaltoLinha := 50       
Private nPagina     := 1
            
Private oFont10
Private oFont11
Private oFont11b
Private oFont12b   
Private oFont13b
Private oFont15b
Private oFont16b
Private oPrint         

Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 10 Negrito
Define Font oFont11    Name "Arial"             Size 0,-09       // Tamanho 11 
Define Font oFont11b   Name "Courier New"       Size 0,-09 Bold  // Tamanho 11 Negrito
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito
Define Font oFont13b   Name "Courier New"       Size 0,-11 Bold  // Tamanho 13 Negrito  
Define Font oFont15b   Name "Courier New"       Size 0,-13 Bold  // Tamanho 15 Negrito
Define Font oFont16b   Name "Courier New"       Size 0,-14 Bold  // Tamanho 16 Negrito
     

If Len(aArqs) > 0
     
oPrint:= TMSPrinter():New("EDI IMPORTACAO")
oPrint:SetPortrait() 	// Retrato
oPrint:SetPaperSize(9)	// Seta para papel A4 
	 	
// startando a impressora
oPrint:Say(0, 0," ",oFont10,100)    

//Imprime cabecalho
Cabecalho()

oPrint:Say (nLinha,nColInic,"PEDIDO(S) DE COMPRA IMPORTADO(S) COM SUCESSO",oFont11b)
nlinha+=nSaltoLinha                                                                 
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
nlinha+=nSaltoLinha

oPrint:Say (nLinha,nColInic       ,"ITEM"                    ,oFont11b)
oPrint:Say (nLinha,nColInic + 150 ,"PED. COMPRA "            ,oFont11b)
//oPrint:Say (nLinha,nColInic + 600 ,"PED. VENDA GERADO ITALAC",oFont11b)
oPrint:Say (nLinha,nColInic + 1150,"NOME DO ARQUIVO"         ,oFont11b)
nlinha+=nSaltoLinha

//Imprime Dados
For nCont:=1 to Len(aArqs)          
                   
	If !aArqs[nCont,6]       
	
		//quebra de pagina
		 If nLinha >= 3300                           
				oPrint:EndPage()	// Finaliza a Pagina.
				oPrint:StartPage()	// Inicia uma nova pagina                  
				nLinha:=0100   
				nPagina++     
				Cabecalho()
		EndIf 
	
		//Imprime os pedidos de compra processados com sucesso              
		oPrint:Say (nLinha,nColInic,StrZero(cNumItem,4),oFont11b)
		oPrint:Say (nLinha,nColInic + 150 ,aArqs[nCont,5],oFont11b)
		oPrint:Say (nLinha,nColInic + 1150,aArqs[nCont,1],oFont11b)
		nlinha+=nSaltoLinha //Talita Teixeira - 14/08/14 - Incluido o salto de linhas pois as informações dos pedidos processados estavam sendo impressos sem o saldo. Chamado: 7077.
		
	cNumItem++      
	
    EndIf

Next nCont       

nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic,"TOTAL DE PEDIDOS DE COMPRA IMPORTADOS COM SUCESSO: " + Str((cNumItem - 1),03),oFont11b)
nlinha+=nSaltoLinha


nlinha+=nSaltoLinha
nlinha+=nSaltoLinha
//Arquivos que apresentaram problema na importacao
oPrint:Say (nLinha,nColInic,"PEDIDO(S) DE COMPRA QUE APRESENTOU(ARAM) PROBLEMA NA IMPORTAÇÃO",oFont11b)
nlinha+=nSaltoLinha                                                                                    
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
nlinha+=nSaltoLinha

oPrint:Say (nLinha,nColInic       ,"ITEM"                 ,oFont11b)
oPrint:Say (nLinha,nColInic + 150 ,"PED. COMPRA CLIENTE"  ,oFont11b)
oPrint:Say (nLinha,nColInic + 600 ,"PED. VENDA ITALAC"    ,oFont11b)
oPrint:Say (nLinha,nColInic + 1000,"NOME DO ARQUIVO"      ,oFont11b)
oPrint:Say (nLinha,nColInic + 1500,"PROBLEMA"             ,oFont11b)
nlinha+=nSaltoLinha
 
cNumItem:= 1

//Imprime Dados
For nCont:=1 to Len(aArqs)          
                   
	If aArqs[nCont,6]         
	
				//quebra de pagina
		 If nLinha >= 3300                           
				oPrint:EndPage()	// Finaliza a Pagina.
				oPrint:StartPage()	// Inicia uma nova pagina                  
				nLinha:=0100   
				nPagina++     
				Cabecalho()
		EndIf
	
		oPrint:Say (nLinha,nColInic,StrZero(cNumItem,4),oFont11b)
		oPrint:Say (nLinha,nColInic + 150 ,aArqs[nCont,5],oFont11b)
		oPrint:Say (nLinha,nColInic + 600,aArqs[nCont,3],oFont11b)
		oPrint:Say (nLinha,nColInic + 1000,SubStr(aArqs[nCont,1],1,31),oFont11b)
		oPrint:Say (nLinha,nColInic + 1500,aArqs[nCont,4],oFont11b)
		nlinha+=nSaltoLinha
	
	cNumItem++       
	
	EndIf

Next nCont
                   
nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic,"TOTAL DE PEDIDOS DE COMPRA QUE APRESNTARAM PROBLEMA NA IMPORTAÇÃO: " + Str((cNumItem - 1),03),oFont11b)

oPrint:Preview()	// Visualiza antes de Imprimir.                                                

	Else
	
		MsgInfo ("Não foi importado nenhum arquivo, favor vericar a localização do(s) arquivo(s)") // Comentado por Abrahao em 24/06/09

EndIf

Return                                                                               

/*
===============================================================================================================================
Programa----------: Cabecalho
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: Funcao utilizada montagem do Cabeçalho
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/   
Static Function Cabecalho()

Local cRaizServer := If(issrvunix(), "/", "\")    

	oPrint:SayBitmap(nLinha,0100,cRaizServer + "system/lgrl01.bmp",250,100)   
	nlinha+=(nSaltoLinha * 3) 
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	
	nlinha+=nSaltoLinha - 30
	//DADOS DA EMPRESA
	oPrint:Say (nLinha,0100,SM0->M0_NOMECOM,oFont11b)
	oPrint:Say (nlinha,1250,"C.N.P.J.: " + formCPFCNPJ(SM0->M0_CGC),oFont11b) // Picture "@R! NN.NNN.NNN/NNNN-99"
	nlinha+=nSaltoLinha
	
	oPrint:Say (nlinha,0100,AllTrim(SM0->M0_ENDCOB),oFont11b)
	oPrint:Say (nlinha,1250,"Insc.: " + AllTrim(SM0->M0_INSC),oFont11b)       
	oPrint:Say (nlinha,2000,"Pagina: " + Str(nPagina,3),oFont11b)
	nlinha+=nSaltoLinha     	

	oPrint:Say (nlinha,0100,AllTrim(SM0->M0_CIDCOB) + " - " + AllTrim(SM0->M0_ESTCOB),oFont11b)
	oPrint:Say (nlinha,1250,"CEP: " + SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3),oFont11b)
	oPrint:Say (nlinha,2000,"Emissão: " + DToC(date()),oFont11b)
	nlinha+=nSaltoLinha
	//FIM DADOS DA EMPRESA
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
	nlinha+=nSaltoLinha
	//TITULO DO RELATORIO COM O PERIODO INFORMADO PELO USUARIO      
	oPrint:Say (nlinha,1165,"RELAÇÃO DE IMPORTACAO DE PEDIDO(S) DE COMPRA",oFont11b,nColFinal,,,2)
	nlinha+=nSaltoLinha                                            
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha

Return  

/*
===============================================================================================================================
Programa----------: formCPFCNPJ
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: Funcao utilizada formatar o CNPJ
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/   
Static Function formCPFCNPJ(cCPFCNPJ)

Local cCampFormat:=""//Armazena o CPF ou CNPJ formatado
   
   //CPF                            
	If Len(AllTrim(cCPFCNPJ)) == 11
	
		cCampFormat:=SubStr(cCPFCNPJ,1,3) + "." + SubStr(cCPFCNPJ,4,3) + "." + SubStr(cCPFCNPJ,7,3) + "-" + SubStr(cCPFCNPJ,10,2) 
		
		Else//CNPJ       
		
			cCampFormat:=SubStr(cCPFCNPJ,1,2)+"."+SubStr(cCPFCNPJ,3,3)+"."+SubStr(cCPFCNPJ,6,3)+"/"+SubStr(cCPFCNPJ,9,4)+"-"+ SubStr(cCPFCNPJ,13,2)
			
	EndIf
	
Return cCampFormat

/*
===============================================================================================================================
Programa----------: C 
Autor-------------: Norbert/Ernani/Mansano
Data da Criacao---: 10/05/2005
Descrição---------: Funcao responsavel por manter o Layout independente da resolucao horizontal do Monitor do Usuario.
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/     
Static Function C(nTam)                                                         

Local nHRes	:=	oMainWnd:nClientWidth	// Resolucao horizontal do monitor     
	If nHRes == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)  
		nTam *= 0.8                                                                
	ElseIf (nHRes == 798).Or.(nHRes == 800)	// Resolucao 800x600                
		nTam *= 1   	                                                               
	Else	// Resolucao 1024x768 e acima faz proporcao                                          
		nTam = (nTam * 1)                                                               
	EndIf                                                                         
                                                                                
	//Tratamento para tema Flat
	If "MP8" $ oApp:cVersion                                                      
		If (AllTrim(GetTheme()) == "FLAT") .Or. SetMdiChild()                      
			nTam *= 0.90                                                            
		EndIf                                                                      
	EndIf                                                                         
Return Int(nTam)      

/*
===============================================================================================================================
Programa----------: RenArquivos
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/02/2010
Descrição---------: Funcao utilizada para Renomear os arquivos recebido.
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/                                                             
Static Function RenArquivos()   
     
Local nStatus := 0 
Local i			:= 0          
For i:=1 to Len(aArqs)      
    	
 
	//Caso nao tenha encontrado problema na importacao do pedido de compra 
	//do cliente e realizado a alteracao do tipo do arquivo de pedido de compra.
 
	If !aArqs[i,6]

		nStatus := frename(cPath + aArqs[i,1],cPath + SubStr(aArqs[i,1],1,AT('EDI',aArqs[i,1] )-1) + 'BKP')  
	
		If nStatus == - 1
			MsgStop('Falha para renomear o arquivo ' + aArqs[i,1] + ' - ' + Str(ferror(),4))
		EndIf
	
	EndIf 

Next i   

Return
