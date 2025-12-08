#Include "TOTVS.ch"
#Include "RPTDEF.CH" 

/*
===============================================================================================================================
Programa----------: PCTITQRY
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/12/2025
Descrição---------: Ponto de entrada utilizado para alteração da query responsável pela listagem
                    dos títulos no Portal do Cliente - FIN. Chamado 52641.
Parametros--------: - Paramixb[1] (Character) = Query padrão criada até o momento para listagem.
                    - Paramixb[2] (Array) = Lista contendo a chave dos clientes selecionados no portal.
                                            Variável no formato Json/Array contendo a filial, código e loja de 
                                            todos os clientes listados em tela. 
                                            Exemplo:
                                            Paramixb[2][1] = Json
                                                    filial = "   "
                                                    codigo = "023781"
                                                    loja   = "0002"
                                            Paramixb[2][2] = Json
                                                    filial = "   "
                                                    codigo = "023781"
                                                    loja   = "0003"
                                            Paramixb[2][3] = Json
                                                    filial = "   "
                                                    codigo = "023781"
                                                    loja   = "0004"
Retorno-----------: - cNewQuery (Character) = Query customizada com os filtros aplicados.
===============================================================================================================================
*/
User Function PCTITQRY()
Local _cNovaQuery := "" As Character
Local _cQueryOrg  := Paramixb[1] As Array
//Local _aChaveCli := Paramixb[2] As Array
Local _nI        := 0 As Numeric
Local _cQry1     := "" As Character
Local _cQry2     := "" As Character
Local _nTamQry   := 0  As Numeric

Begin Sequence 
   //============================================================
   // Define o filtro E1_NUMBCO.
   //============================================================
   _cQueryOrg := Upper(AllTrim(_cQueryOrg))
   _nTamQry   := Len(_cQueryOrg)
   _nI := AT( "ORDER BY", _cQueryOrg )
   If _nI > 0
      _cQry1 := SubStr(_cQueryOrg,1,_nI-1)
      _cQry2 := SubStr(_cQueryOrg,_nI,_nTamQry)
      _cQueryOrg := _cQry1 + " AND E1_NUMBCO <> ' ' " + _cQry2
   EndIf
   
   //============================================================
   // Define a exibição das informações do vencimento real.
   //============================================================
   _nTamQry   := Len(_cQueryOrg)
   _nI := AT( "SE1.E1_VENCREA,", _cQueryOrg )

   If _nI > 0
      _cQry1 := SubStr(_cQueryOrg,1,_nI-1)
      _cQry2 := SubStr(_cQueryOrg,_nI+15,_nTamQry)
      _cNovaQuery := _cQry1 + " CASE WHEN TRIM(E1_I_DTPRO) <>' ' THEN E1_I_DTPRO ELSE E1_VENCTO END AS E1_VENCREA, " + _cQry2
   Else
      _nI := AT( "E1_VENCREA,", _cQueryOrg )
      If _nI > 0
         _cQry1 := SubStr(_cQueryOrg,1,_nI-1)
         _cQry2 := SubStr(_cQueryOrg,_nI+11,_nTamQry)
         _cNovaQuery := _cQry1 + " CASE WHEN TRIM(E1_I_DTPRO) <>' ' THEN E1_I_DTPRO ELSE E1_VENCTO END AS E1_VENCREA, " + _cQry2
      Else 
         _cNovaQuery := _cQueryOrg
      EndIf 
   EndIf 

   //============================================================
   // Inclui a NDC no filtro E1_TIPO.
   //============================================================
   _nTamQry   := Len(_cNovaQuery)
   _nI := AT( "E1_TIPO NOT IN (", _cNovaQuery)

   If _nI > 0
      _cQry1 := SubStr(_cNovaQuery,1,_nI+15)
      _cQry2 := SubStr(_cNovaQuery,_nI+16,_nTamQry)
      _cNovaQuery := _cQry1 + "'NDC'," + _cQry2
   EndIf 
    
End Sequence

Return _cNovaQuery
