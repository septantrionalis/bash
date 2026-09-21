#!/bin/bash

# Script to cleanse a HAMRS generated ADIF file and save it as a POTA and WWFF ADIF file.
# Author: KC0ZPS
#
# Updated:
# - Prints the callsign/QSO causing required-field count mismatches.
# - Fixes quoted filename handling when output filenames contain spaces.
# - Keeps validation non-fatal for count mismatches unless you uncomment exit 1 in verify_counts.

CALLSIGN='KC0ZPS'

RED='\033[31m'
GREEN='\033[32m'
ORANGE='\033[38;5;208m'
CYAN='\033[0;36m'
BLUE='\033[34m'
DARKGREY='\033[90m'
WHITE='\033[97m'
NOCOLOR='\033[0m'

PROCESSWWFF=1

declare -a kv_store=()

CALL_KEY="<CALL:"
EOR_KEY="<EOR"
COMMENT_KEY="<COMMENT:"
MY_SIG_KEY="<MY_SIG:"
MY_SIG_INFO_KEY="<MY_SIG_INFO:"
RST_RCVD_KEY="<RST_RCVD:"
RST_SENT_KEY="<RST_SENT:"
OPERATOR_KEY="<OPERATOR:"
GRIDSQUARE_KEY="<GRIDSQUARE:"
MYGRIDSQUARE_KEY="<MY_GRIDSQUARE:"
BAND_KEY="<BAND:"
FREQ_KEY="<FREQ:"
TIMEON_KEY="<TIME_ON:"
QSODATE_KEY="<QSO_DATE:"
MODE_KEY="<MODE:"
TXPOWER_KEY="<TX_PWR:"
MYPOTAREF_KEY="<MY_POTA_REF:"
NAME_KEY="<NAME:"
QTH_KEY="<QTH:"
STATE_KEY="<STATE:"
COUNTY_KEY="<CNTY:"
COUNTRY_KEY="<COUNTRY:"
MYSTATE_KEY="<MY_STATE:"

initialize_keys() {
    # POTA references sorted lexicographically. Source: https://cqparks.net/dualparks/
    # Retrieved 2026-09-20; site includes 2026-06-07 KFF additions (NA/SA).
    # Ambiguous matches retain an existing choice or use NIL-0000; candidates follow.
    # All keys below are unique, so initialization can append without scanning.
    local initializing_keys=1
    kv_store=()
    set_key AG-0004 V2FF-0001  # Nelson's Dockyard
    set_key AI-0004 VPFF-2002  # Shoal Bay-Island Harbour Marine Park (VP2E)
    set_key AI-0005 VPFF-2007  # Prickly Pear Marine Park (VP2E)
    set_key AI-0006 VPFF-2005  # Park Dog Island Marine Park (VP2E)
    set_key AI-0007 VPFF-2012  # Sombrero Island Nature Reserve (VP2E)
    set_key AQ-0001 KFF-0073  # Amundsen-Scott South Pole Station Antarctic Station
    set_key AQ-0002 KFF-0074  # Beardmore South Camp Antarctic Station
    set_key AQ-0003 KFF-0075  # Brockton II Antarctic Station
    set_key AQ-0004 KFF-0076  # Byrd Station Antarctic Station
    set_key AQ-0005 KFF-0077  # Byrd Surface Camp Antarctic Station
    set_key AQ-0006 KFF-0078  # Byrd VLF Substation Antarctic Station
    set_key AQ-0007 KFF-0079  # Central West Camp Antarctic Station
    set_key AQ-0008 KFF-0080  # Dome Charlie Antarctic Station
    set_key AQ-0009 KFF-0081  # Downstream Bravo Camp Antarctic Station
    set_key AQ-0010 KFF-0082  # East Camp Vostok Antarctic Station
    set_key AQ-0011 KFF-0083  # Eights Station (Sky High) Camp
    set_key AQ-0012 KFF-0084  # Fuchs Sound Camp Antarctic Station
    set_key AQ-0013 KFF-0085  # Hallett Station
    set_key AQ-0014 KFF-0086  # Leverett Glacier Camp Antarctic Station
    set_key AQ-0015 KFF-0087  # Little America V Station
    set_key AQ-0016 KFF-0088  # Little Rockford II Station
    set_key AQ-0017 KFF-0089  # Marble Point Camp Antarctic Station
    set_key AQ-0018 KFF-0090  # McMurdo Station Antarctic Station
    set_key AQ-0019 KFF-0091  # North Victoria Land Camp
    set_key AQ-0020 KFF-0092  # Palmer Station Antarctic Station
    set_key AQ-0021 KFF-0093  # Pieter J. Lenie Field Station (Copacabana) Antarctic Station
    set_key AQ-0022 KFF-0094  # Plateau Station
    set_key AQ-0023 KFF-0095  # Siple Dome Camp Antarctic Station
    set_key AQ-0024 KFF-0096  # Siple Station Antarctic Station
    set_key AQ-0025 KFF-0097  # Terra Nova Bay Camp Antarctic Station
    set_key AQ-0026 KFF-0098  # Upper West Station Camp Antarctic Station
    set_key AQ-0027 KFF-0099  # Upstream B Camp Antarctic Station
    set_key AQ-0028 KFF-0100  # Upstream C Camp Antarctic Station
    set_key AQ-0029 KFF-0101  # Wilkes Station Antarctic Station
    set_key AQ-0030 KFF-0102  # Williams Field Antarctic Station
    set_key AQ-0058 CEFF-0036  # General Bernardo O'Higgins Riqueime Base (Army)
    set_key AR-0001 LUFF-0008  # El Leoncito
    set_key AR-0002 LUFF-0031  # San Guillermo
    set_key AR-0003 LUFF-0185  # Reserva de la Biosfera San Guillermo
    set_key AR-0004 LUFF-0174  # Area Natural La CIENAGA
    set_key AR-0005 LUFF-0013  # Ischigualasto
    set_key AR-0006 LUFF-0175  # Reserva del Valle FERTIL
    set_key AR-0008 LUFF-0124  # Loma de las TAPIAS
    set_key AR-0009 LUFF-0176  # Afloramiento Limo Arcillosos
    set_key AR-0010 LUFF-0177  # P. Pcial Presidente Sarmiento
    set_key AR-0011 LUFF-0178  # Paisaje Protegido El Pedernal
    set_key AR-0013 LUFF-0179  # Monumento Natural Alcazar
    set_key AR-0014 LUFF-0180  # Reserva Don Carmelo
    set_key AR-0015 LUFF-0181  # Refugio Vida Silvestre Los Morillos
    set_key AR-0017 LUFF-0063  # Bah�a San Blas-Bah�a Anegada
    set_key AR-0018 LUFF-0064  # Isla Martin Garcia
    set_key AR-0019 LUFF-0072  # Tornquist, Ernesto
    set_key AR-0020 LUFF-0094  # MAR CHIQUITA
    set_key AR-0021 LUFF-0095  # CHASIC�
    set_key AR-0022 LUFF-0096  # BARRANCA NORTE
    set_key AR-0023 LUFF-0097  # Pereira IRAOLA
    set_key AR-0026 LUFF-0136  # COSTERO DEL SUR
    set_key AR-0027 LUFF-0139  # Faro Querandi
    set_key AR-0029 LUFF-0150  # Res. Nat. AVELLANEDA
    set_key AR-0030 LUFF-0151  # P.N. Ciervo de Los Pantanos
    set_key AR-0031 LUFF-0152  # Res. Nat Mun. RIBERA NORTE
    set_key AR-0032 LUFF-0153  # R. Nat. Guardia del JUNCAL
    set_key AR-0033 LUFF-0161  # Reserva Mun. Img. Maschwitz
    set_key AR-0034 LUFF-0165  # Delta del Paran�
    set_key AR-0035 LUFF-0071  # Costanera Sur
    set_key AR-0036 LUFF-0065  # Laguna Blanca
    set_key AR-0037 LUFF-0100  # Lagunas Altoandinas y Pune�as de Catamarca
    set_key AR-0038 LUFF-0004  # Chaco
    set_key AR-0039 LUFF-0058  # Colonia Benitez
    set_key AR-0040 LUFF-0089  # P.N. El IMPENETRABLE
    set_key AR-0041 LUFF-0014  # Lago Puelo
    set_key AR-0042 LUFF-0018  # Los Alerces
    set_key AR-0043 LUFF-0062  # Patagonia Austral
    set_key AR-0044 LUFF-0068  # Punta Tombo
    set_key AR-0045 LUFF-0069  # Bosque Petrificado Sarmiento
    set_key AR-0046 LUFF-0070  # Peninsula Vald
    set_key AR-0047 LUFF-0090  # PATAGONIA AZUL
    set_key AR-0048 LUFF-0091  # R.N.D. Punta BUENOS AIRES
    set_key AR-0049 LUFF-0092  # Punta del MARQU�S
    set_key AR-0050 LUFF-0142  # Cabo dos Bah�as
    set_key AR-0051 LUFF-0143  # Lago Epuy�n
    set_key AR-0052 LUFF-0005  # Chancani
    set_key AR-0053 LUFF-0028  # Quebrada del Condorito
    set_key AR-0054 LUFF-0066  # Laguna Mar Chiquita
    set_key AR-0055 LUFF-0101  # Reserva. VAQUER�AS
    set_key AR-0056 LUFF-0102  # La Quebrada
    set_key AR-0057 LUFF-0158  # Res Cerro Colorado
    set_key AR-0058 LUFF-0104  # ASCOCHINGA
    set_key AR-0059 LUFF-0105  # Salinas GRANDES
    set_key AR-0060 LUFF-0106  # Monte de BARRACAS
    set_key AR-0061 LUFF-0138  # Pampa de Achala
    set_key AR-0062 LUFF-0147  # Laguna La Felipa
    set_key AR-0063 LUFF-0148  # R.N M Francisco TAU
    set_key AR-0065 LUFF-0023  # Mburucuy
    set_key AR-0066 LUFF-0067  # Ibera
    set_key AR-0068 LUFF-0108  # Zanj�n de LORETO
    set_key AR-0069 LUFF-0109  # Apip� GRANDE
    set_key AR-0070 LUFF-0007  # PRE DELTA -(Diamante)
    set_key AR-0071 LUFF-0009  # El Palmar
    set_key AR-0072 LUFF-0110  # El GATO y Lomas LIMPIAS
    set_key AR-0073 LUFF-0111  # Islote CURUP�
    set_key AR-0074 LUFF-0030  # Rio Pilcomayo
    set_key AR-0075 LUFF-0060  # Formosa (ZN D.RB)
    set_key AR-0076 LUFF-0112  # Riacho TEUQUITO
    set_key AR-0077 LUFF-0113  # Laguna OCA- Herradura r�o Paraguay
    set_key AR-0078 LUFF-0002  # Calilegua
    set_key AR-0079 LUFF-0061  # Laguna de los Pozuelos
    set_key AR-0080 LUFF-0085  # Yungas-2 Biosphere
    set_key AR-0081 LUFF-0086  # Quebrada de Humahuaca
    set_key AR-0082 LUFF-0017  # Lihue Calel
    set_key AR-0083 LUFF-0114  # Parque LURO
    set_key AR-0084 LUFF-0115  # Pichi MAHUIDA
    set_key AR-0085 LUFF-0116  # Reserva Nat. Casa de PIEDRA
    set_key AR-0087 LUFF-0033  # Talampaya
    set_key AR-0088 LUFF-0117  # Ref. Provincial Laguna BRAVA
    set_key AR-0089 LUFF-0074  # Cerro Aconcagua
    set_key AR-0090 LUFF-0081  # Caverna de Las Brujas
    set_key AR-0091 LUFF-0119  # Manzano HIST�RICO
    set_key AR-0092 LUFF-0120  # NACU�AN
    set_key AR-0093 LUFF-0170  # Parque Pcial. Cordon del Plata
    set_key AR-0094 LUFF-0171  # Reserva La Payunia
    set_key AR-0095 LUFF-0012  # Iguazu
    set_key AR-0097 LUFF-0082  # Yabot
    set_key AR-0098 LUFF-0162  # Parque Prov. Canadon de Profundidad
    set_key AR-0099 LUFF-0172  # Parque Pcial. Salto Encantado
    set_key AR-0100 LUFF-0015  # Laguna Blanca
    set_key AR-0101 LUFF-0016  # Lan
    set_key AR-0102 LUFF-0019  # Los Arrayanes
    set_key AR-0103 LUFF-0075  # El Tromen
    set_key AR-0104 LUFF-0083  # Auca Mahuida
    set_key AR-0105 LUFF-0160  # P. Pcial.Copahue Caviahue
    set_key AR-0106 LUFF-0025  # Nahuel Huapi
    set_key AR-0107 LUFF-0073  # Bah�a de San Antonio
    set_key AR-0108 LUFF-0076  # Caleta de Los Loros
    set_key AR-0109 LUFF-0077  # Punta Bermeja
    set_key AR-0110 LUFF-0145  # Mesta de Somuncura
    set_key AR-0111 LUFF-0146  # Valle Cret�cico
    set_key AR-0112 LUFF-0155  # Reserva Bubalco
    set_key AR-0113 LUFF-0157  # Reserva Paso C�rdova
    set_key AR-0114 LUFF-0159  # Reserva Pcial. Rio LIMAY
    set_key AR-0115 LUFF-0168  # Area Nat. Protegida Islote Lobos
    set_key AR-0116 LUFF-0006  # Copo
    set_key AR-0117 LUFF-0093  # Reserva Prov COPO
    set_key AR-0118 LUFF-0001  # Baritu
    set_key AR-0119 LUFF-0010  # El Rey
    set_key AR-0120 LUFF-0020  # Los Cardones
    set_key AR-0121 LUFF-0078  # Los Andes
    set_key AR-0122 LUFF-0084  # Yungas-1
    set_key AR-0123 LUFF-0123  # Nogalar de los TOLDOS
    set_key AR-0124 LUFF-0032  # Sierra de Las Quijadas
    set_key AR-0126 LUFF-0011  # Francisco Perito Moreno
    set_key AR-0127 LUFF-0021  # Los Glaciares
    set_key AR-0128 LUFF-0024  # Monte Le�n
    set_key AR-0129 LUFF-0026  # P.N. PATAGONIA
    set_key AR-0130 LUFF-0029  # Ria de Puerto Deseado
    set_key AR-0131 LUFF-0126  # Cabo V�RGENES
    set_key AR-0132 LUFF-0059  # Bosques Petrificados
    set_key AR-0133 LUFF-0129  # P. Interj. Marino MAKENKE
    set_key AR-0134 LUFF-0130  # P. Interj. Marino ISLA PING�INO
    set_key AR-0135 LUFF-0140  # Aves Migratorias
    set_key AR-0136 LUFF-0141  # Laguna AZUL
    set_key AR-0137 LUFF-0144  # Bah�a Laura
    set_key AR-0138 LUFF-0154  # Res. Costera R�o Gallegos
    set_key AR-0139 LUFF-0131  # Laguna MELINCU�
    set_key AR-0140 LUFF-0137  # P.N. Islas de SANTA FE
    set_key AR-0141 LUFF-0156  # Jaaukanigas
    set_key AR-0142 LUFF-0169  # Area Protegida J.F Villarino
    set_key AR-0143 LUFF-0034  # Tierra del Fuego
    set_key AR-0144 LUFF-0080  # Isla de Los Estados
    set_key AR-0145 LUFF-0088  # Coraz�n de la ISLA
    set_key AR-0146 LUFF-0133  # Costa Atlantica Tierra del Fuego
    set_key AR-0147 LUFF-0087  # R. Nat. Santa ANA
    set_key AR-0148 LUFF-0134  # HORCO MOLLE
    set_key AR-0150 LUFF-0163  # Parque Prov. La Florida
    set_key AR-0151 LUFF-0164  # Pque. Sierra de San Javier
    set_key AR-0152 LUFF-0173  # Parque Nacional ACONQUIJA
    set_key AR-0168 LUFF-0184  # Reserva Ecologica Ciudad Universitaria
    set_key AR-0192 LUFF-0186  # Parque Municipal Llao Llao
    set_key AR-0193 LUFF-0187  # Res. Natural Urbana El Trebol
    set_key AR-0227 LUFF-0098  # R.N.D. Mar CHIQUITA
    set_key AR-0232 LUFF-0189  # Res, Nat.Urb. Lag Morenito Lgna.Ezquerra
    set_key AR-0276 LUFF-0167  # Reserva Natural Urbana Benicio Perez
    set_key AR-0324 LUFF-0203  # Reserva Natural Las junturas
    set_key AR-0325 LUFF-0201  # Reserva H�drica Los Gigantes
    set_key AR-0339 LUFF-0205  # �rea Protegida Sierras de Pocho y Ojo de Agua
    set_key AR-0342 LUFF-0193  # Parque Natural Provincial Islas y Canales Verdes del R�o Uruguay
    set_key AR-0344 LUFF-0198  # Campos del Tuy�
    set_key AR-0351 LUFF-0194  # Reserva Natural Punta Rasa
    set_key AR-0359 LUFF-0206  # Reserva de Biodiversidad - Reserva Nativa
    set_key AR-0362 LUFF-0211  # Camino del Peregrino Area Protegida
    set_key AR-0366 LUFF-0118  # Laguna BRAVA - Ramsar
    set_key AS-0001 KFF-0053  # American Samoa National Park
    set_key AS-0002 KFF-0130  # Rose Atoll National Wildlife Refuge
    set_key AS-0004 KFF-6575  # Swains Island Marine Sanctuary of A. Samoa National Marine Park
    set_key AW-0001 P4FF-0001  # Arikok National Park (P4)
    set_key BB-0004 8PFF-0005  # Folkstone Marine Park and Visitor Centre National Park
    set_key BB-0005 8PFF-0001  # Farley Hill National Park
    set_key BB-0024 8PFF-0003  # Harrisons Cave And Welchmans Hall Gully
    set_key BM-0020 NIL-0000  # Somerset Long Bay Park
    set_key BQ-0002 PAFF-0023  # Washington Slagbaai Provincial Park (PJ4)
    set_key BQ-0011 PAFF-0026  # Quill/Boven Provincial Park (PJ5)
    set_key BQ-0012 PAFF-0027  # Saba National Marine Park Provincial Park (PJ5)
    set_key BR-0001 PYFF-0244  # Alto Cariri National Conservation Area
    set_key BR-0002 PYFF-0002  # Amaz�nia National Park
    set_key BR-0003 PYFF-0212  # Anavilhanas National Park
    set_key BR-0004 PYFF-0003  # Aparados da Serra National Park
    set_key BR-0005 PYFF-0003  # Aparados da Serra National Conservation Area
    set_key BR-0006 PYFF-0304  # Araguaia National Park
    set_key BR-0008 PYFF-0376  # Boa Nova National Conservation Area
    set_key BR-0010 PYFF-0082  # Bras�lia National Forest
    set_key BR-0011 PYFF-0007  # Cabo Orange National Conservation Area
    set_key BR-0012 PYFF-0255  # Campos Amaz�nicos National Conservation Area
    set_key BR-0013 PYFF-0255  # Campos Amaz�nicos National Conservation Area
    set_key BR-0015 PYFF-0008  # Campos Gerais National Conservation Area
    set_key BR-0016 PYFF-0009  # Capara� National Conservation Area
    set_key BR-0017 PYFF-0056  # Vale do Catimbau National Conservation Area
    set_key BR-0018 PYFF-0010  # Caverna do Parua�u National Conservation Area
    set_key BR-0019 PYFF-0011  # Chapada das Mesas National Conservation Area
    set_key BR-0020 PYFF-0012  # Chapada Diamantina National Conservation Area
    set_key BR-0021 PYFF-0013  # Chapada dos Guimar�es National Conservation Area
    set_key BR-0022 PYFF-0014  # Chapada dos Veadeiros National Conservation Area
    set_key BR-0023 PYFF-0307  # Descobrimento National Conservation Area
    set_key BR-0024 PYFF-0015  # Emas National Conservation Area
    set_key BR-0025 PYFF-0381  # Furna Feia National Conservation Area
    set_key BR-0026 PYFF-0017  # Grande Sert�o Veredas National Conservation Area
    set_key BR-0027 PYFF-0409  # Guaricana National Conservation Area
    set_key BR-0030 PYFF-0020  # Itatiaia National Conservation Area
    set_key BR-0031 PYFF-0146  # Jamanxim National Conservation Area
    set_key BR-0033 PYFF-0022  # Jericoacoara National Conservation Area
    set_key BR-0035 PYFF-0023  # Lagoa dos Peixes National Conservation Area
    set_key BR-0036 PYFF-0024  # Len��is Maranhenses National Conservation Area
    set_key BR-0037 PYFF-0214  # Maringuari National Conservation Area
    set_key BR-0038 PYFF-0214  # Maringuari National Conservation Area
    set_key BR-0039 PYFF-0016  # Marinho de Fernando de Noronha National Conservation Area
    set_key BR-0040 PYFF-0383  # Marinho das Ilhas dos Currais National Conservation Area
    set_key BR-0041 PYFF-0636  # Marinho de Abrolhos National Conservation Area
    set_key BR-0042 PYFF-0054  # Montanhas do Tumucumaque National Conservation Area
    set_key BR-0043 PYFF-0025  # Monte Pascoal National Conservation Area
    set_key BR-0044 PYFF-0026  # Monte Roraima National Conservation Area
    set_key BR-0045 PYFF-0215  # Nascentes do Lago Jari National Conservation Area
    set_key BR-0050 PYFF-0028  # Paca�s Novos National Conservation Area
    set_key BR-0051 PYFF-0029  # Pantanal Matogrossense National Conservation Area
    set_key BR-0052 PYFF-0030  # Pau Brasil National Conservation Area
    set_key BR-0053 PYFF-0032  # Pico da Neblina National Conservation Area
    set_key BR-0054 PYFF-0226  # Restinga de Jurubatiba National Conservation Area
    set_key BR-0055 PYFF-0156  # Rio Novo National Conservation Area
    set_key BR-0056 PYFF-0034  # Saint-Hilaire/Lange National Conservation Area
    set_key BR-0057 PYFF-0035  # S�o Joaquim National Conservation Area
    set_key BR-0058 PYFF-0036  # Sempre-vivas National Conservation Area
    set_key BR-0059 PYFF-0037  # Serra da Bocaina National Conservation Area
    set_key BR-0060 PYFF-0037  # Serra da Bocaina National Conservation Area
    set_key BR-0061 PYFF-0038  # Serra da Bodoquena National Conservation Area
    set_key BR-0062 PYFF-0039  # Serra da Canastra National Conservation Area
    set_key BR-0063 PYFF-0040  # Serra da Capivara National Conservation Area
    set_key BR-0064 PYFF-0044  # Serra do Cip� National Conservation Area
    set_key BR-0065 PYFF-0213  # Serra das Confus�es National Conservation Area
    set_key BR-0066 PYFF-0041  # Serra da Cutia National Conservation Area
    set_key BR-0067 PYFF-0414  # Serra das Lontras National Conservation Area
    set_key BR-0068 PYFF-0042  # Serra da Mocidade National Conservation Area
    set_key BR-0069 PYFF-0043  # Serra de Itabaiana National Conservation Area
    set_key BR-0070 PYFF-0045  # Serra do Divisor National Conservation Area
    set_key BR-0071 PYFF-0388  # Serra do Gandarela National Conservation Area
    set_key BR-0072 PYFF-0046  # Serra do Itaja� National Conservation Area
    set_key BR-0073 PYFF-0047  # Serra do Pardo National Conservation Area
    set_key BR-0074 NIL-0000  # Serra dos �rg�os National Conservation Area; WWFF candidates: PYFF-0048, PYFF-0315
    set_key BR-0075 PYFF-0049  # Serra Geral National Conservation Area
    set_key BR-0076 PYFF-0049  # Serra Geral National Conservation Area
    set_key BR-0077 PYFF-0051  # Sete Cidades National Conservation Area
    set_key BR-0078 PYFF-0052  # Superag�i National Conservation Area
    set_key BR-0080 PYFF-0055  # Ubajara National Conservation Area
    set_key BR-0082 PYFF-0001  # Abrolhos National Conservation Area
    set_key BR-0084 PYFF-0033  # Monumento Natural dos Pont�es Capixabas National Conservation Area
    set_key BR-0086 PYFF-0058  # Ind�gena do Xingu National Park Aboriginal
    set_key BR-0087 PYFF-0064  # Arquip�lago S�o Pedro e S�o Paulo Nature Recreation Area
    set_key BR-0088 PYFF-0065  # Arquip�lago Trindade e Martim Vaz Nature Recreation Area
    set_key BR-0090 PYFF-0067  # Reserva Extrativista do Batoque Reserve
    set_key BR-0098 PYFF-0069  # �rea de Prote��o Ambiental da Serra da Meruoca Habitat Protection Area
    set_key BR-0099 PYFF-0071  # Esta��o Ecol�gica de Aiuaba National Ecological Reserve
    set_key BR-0100 PYFF-0072  # Esta��o Ecol�gica do Castanh�o National Ecological Reserve
    set_key BR-0101 PYFF-0073  # Floresta Nacional do Araripe-Apodi National Conservation Area
    set_key BR-0102 PYFF-0077  # Esta��o Ecol�gica Rio Acre National Ecological Reserve
    set_key BR-0103 PYFF-0466  # Chandless State Park
    set_key BR-0106 PYFF-0664  # Parque Estadual do RIO NEGRO Setor Norte - AM
    set_key BR-0107 PYFF-0665  # Parque Estadual do RIO NEGRO Setor Sul - AM
    set_key BR-0108 PYFF-0661  # Parque Estadual SUMAÚMA - AM
    set_key BR-0109 PYFF-0500  # Serra do Ara�a State Park
    set_key BR-0115 PYFF-0597  # Corumbiara State Park
    set_key BR-0116 PYFF-0596  # Guajar�-Mirim State Park
    set_key BR-0117 PYFF-0595  # Serra dos Reis State Park
    set_key BR-0121 PYFF-0413  # Serra do Conduru State Park
    set_key BR-0122 PYFF-0390  # Serra dos Montes Altos State Park
    set_key BR-0123 PYFF-0557  # Morro do Chap�u State Park
    set_key BR-0124 PYFF-0534  # Sete Passagens State Park
    set_key BR-0125 PYFF-0341  # das Carna�bas State Park
    set_key BR-0126 PYFF-0339  # Marinho da Pedra da Risca do Meio State Park
    set_key BR-0127 PYFF-0342  # S�tio Fund�o State Park
    set_key BR-0128 PYFF-0188  # Bacanga State Park
    set_key BR-0130 PYFF-0454  # Mirador State Park
    set_key BR-0132 PYFF-0622  # Marinho do Parcel de Manuel Lu�s Marine Park
    set_key BR-0133 PYFF-0654  # Parque Estadual do ARATU-PB
    set_key BR-0136 PYFF-0327  # Pedra da Boca State Park
    set_key BR-0137 PYFF-0333  # Trilha dos Cinco Rios State Park
    set_key BR-0138 PYFF-0330  # Mata do Pau-ferro State Park
    set_key BR-0139 PYFF-0329  # Mata do X�m-x�m State Park
    set_key BR-0140 PYFF-0328  # Marinho de Areia Vermelha State Park
    set_key BR-0141 PYFF-0331  # Pico do Jabre State Park
    set_key BR-0143 PYFF-0561  # Mata da Pimenteira State Park
    set_key BR-0149 PYFF-0280  # Ecol�gico da Cachoeira do Urubu State Park
    set_key BR-0151 PYFF-0317  # C�nion do Rio Poti State Park
    set_key BR-0153 PYFF-0364  # Dunas de Natal State Park
    set_key BR-0156 PYFF-0403  # Altamiro de Moura Pacheco State Park
    set_key BR-0158 PYFF-0079  # Do Descoberto State Park
    set_key BR-0160 PYFF-0393  # Para�na State Park
    set_key BR-0161 PYFF-0368  # Dos Pireneus State Park
    set_key BR-0164 PYFF-0408  # Terra Ronca State Park
    set_key BR-0171 PYFF-0401  # Encontro das �guas State Park
    set_key BR-0174 PYFF-0116  # Igarap�s do Juruena State Park
    set_key BR-0184 PYFF-0614  # Nascentes do Rio Taquari State Park
    set_key BR-0185 PYFF-0612  # V�rzeas do Rio Ivinhema State Park
    set_key BR-0186 PYFF-0613  # Pantanal do Rio Negro State Park
    set_key BR-0187 PYFF-0611  # Matas do Segredo State Park
    set_key BR-0188 PYFF-0610  # Prosa State Park
    set_key BR-0189 PYFF-0377  # Ita�nas State Park
    set_key BR-0190 PYFF-0031  # Pedra Azul State Park
    set_key BR-0191 PYFF-0378  # Paulo Cesar Vinha State Park
    set_key BR-0202 PYFF-0375  # Ibitipoca State Park
    set_key BR-0203 PYFF-0357  # Itacolomi State Park
    set_key BR-0204 PYFF-0563  # Lagoa do Cajueiro State Park
    set_key BR-0208 PYFF-0608  # Nova Baden State Park
    set_key BR-0209 PYFF-0410  # Paracatu State Park
    set_key BR-0212 PYFF-0458  # Rio Corrente State Park
    set_key BR-0213 PYFF-0359  # Rio Doce State Park
    set_key BR-0216 PYFF-0411  # Serra das Araras State Park
    set_key BR-0217 PYFF-0404  # Serra do Brigadeiro State Park
    set_key BR-0220 PYFF-0416  # Serra do Intendente State Park
    set_key BR-0226 PYFF-0412  # Sete Sal�es State Park
    set_key BR-0227 PYFF-0620  # Serra do Papagaio State Park
    set_key BR-0232 PYFF-0428  # Costa do Sol State Park
    set_key BR-0233 PYFF-0592  # Desengano State Park
    set_key BR-0236 PYFF-0453  # Lagoa do A�u State Park
    set_key BR-0241 PYFF-0395  # Serra da Tiririca State Park
    set_key BR-0242 PYFF-0365  # Tr�s Picos State Park
    set_key BR-0244 PYFF-0580  # �guas da Billings State Park
    set_key BR-0245 PYFF-0070  # �guas da Prata State Park
    set_key BR-0246 PYFF-0554  # Alberto L�fgren State Park
    set_key BR-0247 PYFF-0523  # ARA (Assessoria da Reforma Agr�ria) State Park
    set_key BR-0248 PYFF-0399  # Campina do Encantado State Park
    set_key BR-0250 PYFF-0334  # Cantareira State Park
    set_key BR-0251 PYFF-0424  # Carlos Botelho State Park
    set_key BR-0252 PYFF-0120  # Caverna do Diabo State Park
    set_key BR-0253 PYFF-0455  # Fontes do Ipiranga State Park
    set_key BR-0254 PYFF-0468  # Furnas do Bom Jesus State Park
    set_key BR-0255 PYFF-0525  # Ilha Anchieta State Park
    set_key BR-0256 PYFF-0430  # Ilha do Cardoso State Park
    set_key BR-0257 PYFF-0451  # Ilhabela State Park
    set_key BR-0258 PYFF-0374  # Intervales State Park
    set_key BR-0260 PYFF-0528  # Itapetinga State Park
    set_key BR-0261 PYFF-0553  # Itingu�u State Park
    set_key BR-0262 PYFF-0429  # Jaragu� State Park
    set_key BR-0263 PYFF-0425  # Juquery State Park
    set_key BR-0264 PYFF-0564  # Jurupar� State Park
    set_key BR-0265 PYFF-0398  # Lagamar de Cananeia State Park
    set_key BR-0266 PYFF-0181  # Mananciais de Campos do Jord�o State Park
    set_key BR-0268 PYFF-0637  # Morro do Diabo State Park
    set_key BR-0269 PYFF-0545  # Prelado State Park
    set_key BR-0270 PYFF-0550  # Nascentes do Paranapanema State Park
    set_key BR-0271 PYFF-0362  # Porto Ferreira State Park
    set_key BR-0272 PYFF-0501  # Restinga de Bertioga State Park
    set_key BR-0273 PYFF-0540  # Rio do Peixe State Park
    set_key BR-0275 PYFF-0356  # Tur�stico do Alto Ribeira State Park
    set_key BR-0277 PYFF-0532  # Vassununga State Park
    set_key BR-0281 PYFF-0639  # Parque Estadual da CABE�A DO CACHORRO - PR
    set_key BR-0283 PYFF-0387  # Ilha do Mel State Park
    set_key BR-0285 PYFF-0590  # Laur�ceas State Park
    set_key BR-0292 PYFF-0738  # Parque Estadual de VILA VELHA - PR
    set_key BR-0301 PYFF-0050  # Mata dos Godoy State Park
    set_key BR-0303 PYFF-0588  # Pico Paran� State Park
    set_key BR-0304 PYFF-0589  # Parque Estadual PICO DO MARUMBI - PR
    set_key BR-0306 PYFF-0708  # Parque Estadual RIO GUARANI - PR
    set_key BR-0307 PYFF-0643  # Parque Estadual do RIO DA ON�A - PR
    set_key BR-0309 PYFF-0587  # Serra da Baitaca State Park
    set_key BR-0310 PYFF-0318  # Espig�o Alto State Park
    set_key BR-0311 PYFF-0319  # Itapeva State Park
    set_key BR-0312 PYFF-0320  # Itapu� State Park
    set_key BR-0316 PYFF-0322  # Espinilho State Park
    set_key BR-0318 PYFF-0323  # Ibitiri� State Park
    set_key BR-0321 PYFF-0751  # Parque Estadual PODOCARPUS - RS
    set_key BR-0323 PYFF-0324  # Tainhas State Park
    set_key BR-0324 PYFF-0326  # Turvo State Park
    set_key BR-0325 PYFF-0325  # Quarta Col�nia State Park
    set_key BR-0326 PYFF-0644  # Parque Estadual ACARA� - SC
    set_key BR-0330 PYFF-0394  # do Rio Vermelho State Park
    set_key BR-0331 PYFF-0370  # Serra do Tabuleiro State Park
    set_key BR-0751 PYFF-0220  # Ambiental Petr�polis Protected Area
    set_key BR-0752 NIL-0000  # Bot�nico do Ceara State Park; WWFF candidates: PYFF-0406, PYFF-0575
    set_key BR-0753 PYFF-0349  # Serra de Baturit� Protected Landscape Area
    set_key BR-0754 PYFF-0354  # Rio Pacoti Protected Landscape Area
    set_key BR-0756 PYFF-0348  # Serra da Aratanha Protected Landscape Area
    set_key BR-0757 PYFF-0068  # Chapada do Araripe Protected Landscape Area
    set_key BR-0758 PYFF-0078  # Prainha do Canto Verde Marine Reserve
    set_key BR-0759 PYFF-0345  # Dunas de Paracuru Protected Landscape Area
    set_key BR-0760 PYFF-0350  # Estu�rio do Rio Cear� Protected Landscape Area
    set_key BR-0761 PYFF-0005  # Arauc�rias National Park
    set_key BR-0764 PYFF-0097  # Silv�nia National Forest
    set_key BR-0768 PYFF-0392  # Municipal da Serra do Japi Biological Reserve
    set_key BR-0771 PYFF-0296  # Ipanema National Forest
    set_key BR-0773 PYFF-0521  # Pedra do Bau Nature Monument
    set_key BR-0778 PYFF-0530  # Nascente do Tiete State Park
    set_key BR-0786 PYFF-0107  # Extrativista Chapada Limpa Reserve
    set_key BR-0794 PYFF-0552  # Jequitib� Park
    set_key BR-0803 PYFF-0555  # Morro de Sao Bento Protected Landscape Area
    set_key BR-0805 PYFF-0088  # Sao Francisco de Paula National Forest
    set_key BR-0806 PYFF-0582  # Edmundo Navarro de Andrade State Forest
    set_key BR-0826 PYFF-0609  # Entorno do Costeiro Protected Area
    set_key BR-0827 PYFF-0270  # Baleia Franca Protected Area
    set_key BR-0828 PYFF-0147  # Tapajos National Forest
    set_key BR-0829 PYFF-0380  # Ilha Comprida Protected Landscape Area
    set_key BR-0830 PYFF-0297  # Lorena National Forest
    set_key BR-0831 PYFF-0127  # Passa Quatro National Forest
    set_key BR-0832 PYFF-0640  # Parque Estadual de S�O CAMILO - PR
    set_key BR-0834 PYFF-0074  # Floresta Nacional de SOBRAL - CE
    set_key BR-0836 PYFF-0444  # Parque Estadual das ÁGUAS - CE
    set_key BR-0837 PYFF-0569  # Floresta de BATATAIS - SP
    set_key BR-0838 PYFF-0407  # Parque Estadual do COCÓ - CE
    set_key BR-0840 PYFF-0110  # Reserva Extrativista MATA GRANDE - MA
    set_key BR-0841 PYFF-0108  # Reserva Extrativista CIRIACO - MA
    set_key BR-0842 PYFF-0305  # Reserva Extrativista do EXTREMO NORTE DO TOCANTINS - TO
    set_key BS-0001 C6FF-0001  # Abaco National Park
    set_key BS-0004 C6FF-0005  # Pelican Cays Landand Sea Park
    set_key BS-0011 C6FF-0002  # Conception Island
    set_key BS-0015 C6FF-0003  # Exuma Landand Sea Park
    set_key BS-0019 C6FF-0004  # Inagua National Park
    set_key BZ-0003 V3FF-0002  # Laughing Bird Caye Marine Protected Area
    set_key BZ-0005 V3FF-0014  # Guanacaste National Park
    set_key BZ-0006 V3FF-0009  # Bacalar Chico Marine Protected Area
    set_key BZ-0007 V3FF-0010  # Hall Chan Marine
    set_key BZ-0008 V3FF-0019  # Temas-Sastun
    set_key BZ-0022 V3FF-0005  # Crooked-Tree-Wildlife-Sanctuary
    set_key BZ-0028 V3FF-0003  # Mountain Pine Ridge Forest Reserve
    set_key BZ-0029 V3FF-0015  # Columbia River Forest Reserve
    set_key BZ-0046 V3FF-0013  # Gladden Spit/Silk Cayes Marine Reserve
    set_key BZ-0048 V3FF-0012  # Port Honduras Marine Reserve
    set_key BZ-0049 V3FF-0011  # Sapodilla Cayes Marine Reserve
    set_key BZ-0067 V3FF-0017  # Community Baboon Sanctuary Wildlife Area
    set_key BZ-0069 V3FF-0004  # Rio Bravo Wildlife Area
    set_key BZ-0071 V3FF-0016  # Shipstern Nature Conservation Reserve
    set_key CA-0000 NIL-0000  # Irishtown Nature Park; WWFF candidates: VEFF-2250, VEFF-2254
    set_key CA-0001 VEFF-0001  # Alaksen National Wildlife Area
    set_key CA-0002 VEFF-0002  # Aulavik National Park
    set_key CA-0003 VEFF-0003  # Auyuittuq National Park
    set_key CA-0004 VEFF-0004  # Baie de L’Isle-Verte
    set_key CA-0005 VEFF-0005  # Banff National Park
    set_key CA-0006 VEFF-0006  # Big Creek National Wildlife Area
    set_key CA-0007 VEFF-0007  # Blue Quills National Wildlife Area
    set_key CA-0008 VEFF-0008  # Boot Island National Wildlife Area
    set_key CA-0009 VEFF-0009  # Bradwell National Wildlife Area
    set_key CA-0010 VEFF-0010  # Bruce Peninsula National Park
    set_key CA-0011 VEFF-0011  # CFB Suffield National Wildlife Area
    set_key CA-0012 VEFF-0012  # Cap Tourmente National Wildlife Area
    set_key CA-0013 VEFF-0013  # Cape Breton Highlands National Park
    set_key CA-0014 VEFF-0014  # Cape Jourimain National Wildlife Area
    set_key CA-0015 VEFF-0015  # Charlevoix Biosphere Reserve
    set_key CA-0016 VEFF-0016  # Chignecto National Wildlife Area
    set_key CA-0017 VEFF-0017  # Clayoquot Sound Biosphere Reserve
    set_key CA-0018 VEFF-0018  # Columbia National Wildlife Area
    set_key CA-0020 VEFF-0020  # Elk Island National Park
    set_key CA-0021 VEFF-0021  # Fathom Five National Marine Park of Canada
    set_key CA-0022 VEFF-0022  # Forillon National Park
    set_key CA-0023 VEFF-0023  # Frontenac Arch Biosphere Reserve
    set_key CA-0024 VEFF-0024  # Fundy Biosphere Reserve
    set_key CA-0025 VEFF-0025  # Fundy National Park
    set_key CA-0026 VEFF-0026  # Georgian Bay Islands National Park
    set_key CA-0027 VEFF-0027  # Georgian Bay Littoral Biosphere Reserve
    set_key CA-0028 VEFF-0028  # Glacier National Park
    set_key CA-0029 VEFF-0029  # Grasslands National Park
    set_key CA-0030 VEFF-0030  # Gros Morne National Park
    set_key CA-0031 VEFF-0031  # Gulf Islands National Park Reserve
    set_key CA-0032 VEFF-0032  # Gwaii Haanas and Haida National Park Reserve
    set_key CA-0033 VEFF-0033  # Île-Bonaventure-et-du-Rocher-Percé
    set_key CA-0034 VEFF-0034  # I'le Brion
    set_key CA-0035 VEFF-0035  # Île d'Anticosti
    set_key CA-0036 VEFF-0036  # Îles-de-Contrecoeur
    set_key CA-0037 VEFF-0037  # Îles de l‘Estuaire
    set_key CA-0038 VEFF-0038  # Îles de la Paix
    set_key CA-0039 VEFF-0039  # Ivvavik National Park
    set_key CA-0040 VEFF-0040  # Jasper National Park
    set_key CA-0041 VEFF-0041  # John Lusby Marsh National Wildlife Area
    set_key CA-0042 VEFF-0042  # Kejimkujik National Park and National Historic Site
    set_key CA-0043 VEFF-0043  # Kejimkujik Seaside Adjunct National Park
    set_key CA-0044 VEFF-0044  # Kluane National Park and Reserve
    set_key CA-0045 VEFF-0045  # Kootenay National Park
    set_key CA-0046 VEFF-0046  # Kouchibouguac National Park
    set_key CA-0047 VEFF-0047  # La Mauricie
    set_key CA-0048 VEFF-0048  # Lac Saint-Francois
    set_key CA-0049 VEFF-0049  # Lac Saint-Pierre
    set_key CA-0050 VEFF-0050  # Lake Superior National Marine Area
    set_key CA-0051 VEFF-0051  # Last Mountain Lake National Wildlife Area
    set_key CA-0052 VEFF-0052  # Long Point Biosphere Reserve
    set_key CA-0053 VEFF-0053  # Long Point National Wildlife Area
    set_key CA-0054 VEFF-0054  # Manicouagan-Uapishka
    set_key CA-0055 VEFF-0055  # Meanook National Wildlife Area
    set_key CA-0056 VEFF-0056  # Mingan Archipelago
    set_key CA-0057 VEFF-0057  # Mississippi Lake National Wildlife Area
    set_key CA-0058 VEFF-0058  # Mohawk Island National Wildlife Area
    set_key CA-0059 VEFF-0059  # Mont Saint Hilaire
    set_key CA-0060 VEFF-0060  # Mount Arrowsmith Biosphere Reserve
    set_key CA-0061 VEFF-0061  # Mount Revelstoke National Park
    set_key CA-0062 VEFF-0062  # Nahanni National Park Reserve
    set_key CA-0063 VEFF-0063  # Niagara Escarpment Biosphere Reserve
    set_key CA-0064 VEFF-0064  # Nirjutiqavvik National Wildlife Area
    set_key CA-0065 VEFF-0065  # Nisutlin River Delta National Wildlife Area
    set_key CA-0066 VEFF-0066  # Pacific Rim National Park Reserve
    set_key CA-0067 VEFF-0067  # Point Pelee National Park
    set_key CA-0068 VEFF-0068  # Pointe-au-Pere
    set_key CA-0069 VEFF-0069  # Pointe de l'Est
    set_key CA-0070 VEFF-0070  # Polar Bear Pass National Wildlife Area
    set_key CA-0071 VEFF-0071  # Pope National Wildlife Area
    set_key CA-0072 VEFF-0072  # Portage Island National Wildlife Area
    set_key CA-0073 VEFF-0073  # Portobello Creek National Wildlife Area
    set_key CA-0074 VEFF-0074  # Prairie National Wildlife Area - Unit number 01
    set_key CA-0075 VEFF-0075  # Prince Albert National Park
    set_key CA-0076 VEFF-0076  # Prince Edward Island National Park
    set_key CA-0077 VEFF-0077  # Prince Edward Point National Wildlife Area
    set_key CA-0078 VEFF-0078  # Pukaskwa National Park
    set_key CA-0079 VEFF-0079  # Qualicum National Wildlife Area
    set_key CA-0080 VEFF-0080  # Quttinirpaaq National Park
    set_key CA-0081 VEFF-0081  # Raven Island National Wildlife Area
    set_key CA-0082 VEFF-0082  # Redberry Lake Biosphere Reserve
    set_key CA-0083 VEFF-0083  # Riding Mountain Biosphere Reserve
    set_key CA-0084 VEFF-0084  # Riding Mountain National Park
    set_key CA-0085 VEFF-0085  # Rockwood National Wildlife Area
    set_key CA-0086 VEFF-0086  # Saguenay-St. Lawrence National Marine Par
    set_key CA-0087 VEFF-0087  # Sand Pond National Wildlife Area
    set_key CA-0089 VEFF-0089  # Sea Wolf Island National Wildlife Area
    set_key CA-0090 VEFF-0090  # Shepody National Wildlife Area
    set_key CA-0091 VEFF-0091  # Sirmilik National Park
    set_key CA-0092 VEFF-0092  # South West Nova Biosphere Reserve
    set_key CA-0093 VEFF-0093  # Spiers Lake National Wildlife Area
    set_key CA-0094 VEFF-0094  # St. Clair National Wildlife Area - Bear Creek Unit and St. Clair Unit
    set_key CA-0095 VEFF-0095  # St. Denis National Wildlife Area
    set_key CA-0096 VEFF-0096  # Stalwart National Wildlife Area
    set_key CA-0097 VEFF-0097  # Terra Nova National Park
    set_key CA-0098 VEFF-0098  # Thaydene Nene National Park
    set_key CA-0099 VEFF-0099  # Thousand Islands National Park (SLINP)
    set_key CA-0100 VEFF-0100  # Tintamarre National Wildlife Area
    set_key CA-0101 VEFF-0101  # Torngat Mountains National Park
    set_key CA-0102 VEFF-0102  # Tuktut Nogait National Park
    set_key CA-0103 VEFF-0103  # Tway Lake National Wildlife Area
    set_key CA-0104 VEFF-0104  # Ukkusiksalik National Park
    set_key CA-0105 VEFF-0105  # Vaseux-Bighorn National Wildlife Area
    set_key CA-0106 VEFF-0106  # Vuntut National Park
    set_key CA-0107 VEFF-0107  # Wallace Bay National Wildlife Area
    set_key CA-0108 VEFF-0108  # Wapusk National Park
    set_key CA-0109 VEFF-0109  # Waterton Biosphere Reserve Area
    set_key CA-0110 VEFF-0110  # Waterton Lakes National Park
    set_key CA-0111 VEFF-0111  # Webb National Wildlife Area
    set_key CA-0113 VEFF-0113  # Whitemouth Bog National Wildlife Area
    set_key CA-0114 VEFF-0114  # Widgeon Valley National Wildlife Area
    set_key CA-0115 NIL-0000  # Wood Buffalo National Park (NT only); WWFF candidates: VEFF-0115, VEFF-1831
    set_key CA-0116 VEFF-0116  # Wye Marsh National Wildlife Area
    set_key CA-0117 VEFF-0117  # Yoho National Park
    set_key CA-0118 VEFF-0118  # Dinosaur Provincial Park - Natural Monument
    set_key CA-0120 VEFF-0120  # Sable Island National Park
    set_key CA-0121 VEFF-0121  # Nááts'ihch'oh National Park Reserve
    set_key CA-0122 VEFF-0122  # St. Paul Island National Wildlife Area
    set_key CA-0123 VEFF-0123  # Akpait National Wildlife Area (Reid Bay)
    set_key CA-0124 VEFF-0124  # Niginganiq National Wildlife Area (Isabella Bay)
    set_key CA-0125 VEFF-0125  # Pingo National Landmark
    set_key CA-0126 VEFF-0126  # Qaqulluit National Wildlife Area (Cape Searle)
    set_key CA-0127 VEFF-0127  # Qausuittuq National Park
    set_key CA-0128 VEFF-0128  # Rouge National Urban Park, Bob Hunter Memorial Park
    set_key CA-0129 VEFF-0129  # Ulittaniuik
    set_key CA-0130 VEFF-0130  # Aaron Provincial Park
    set_key CA-0131 VEFF-0131  # Abitibi-De-Troyes Provincial Park
    set_key CA-0132 VEFF-0132  # Adam Creek Provincial Park
    set_key CA-0133 VEFF-0133  # Agassiz Peatlands Provincial Park
    set_key CA-0134 VEFF-0134  # Albany River Provincial Park
    set_key CA-0135 VEFF-0135  # Albert Lake Mesa Provincial Park
    set_key CA-0136 VEFF-0136  # Alexander Stewart Provincial Park
    set_key CA-0137 VEFF-0137  # Algoma Headwaters Provincial Park
    set_key CA-0138 VEFF-0138  # Algonquin Provincial Park
    set_key CA-0139 VEFF-0139  # Arrow Lake Provincial Park
    set_key CA-0140 VEFF-0140  # Arrowhead Provincial Park
    set_key CA-0141 VEFF-0141  # Arrowhead Peninsula Provincial Park
    set_key CA-0142 VEFF-0142  # Aubinadong-Nushatogaini Rivers Provincial Park
    set_key CA-0143 VEFF-0143  # Aubrey Falls Provincial Park
    set_key CA-0144 VEFF-0144  # Awenda Provincial Park
    set_key CA-0145 VEFF-0145  # Balsam Lake Provincial Park
    set_key CA-0146 VEFF-0146  # Bass Lake Provincial Park
    set_key CA-0147 VEFF-0147  # Batchawana Bay Provincial Park
    set_key CA-0148 VEFF-0148  # Bayview Escarpment Provincial Park
    set_key CA-0149 VEFF-0149  # Beattie Pinery Provincial Park
    set_key CA-0150 VEFF-0150  # Beckett Creek Migratory Bird Sanctuary
    set_key CA-0151 VEFF-0151  # Bell Bay Provincial Park
    set_key CA-0152 VEFF-0152  # Big East River Provincial Park
    set_key CA-0153 VEFF-0153  # Bigwind Lake Provincial Park
    set_key CA-0154 VEFF-0154  # Biscotasi Lake Provincial Park
    set_key CA-0155 VEFF-0155  # Black Creek Provincial Park
    set_key CA-0156 VEFF-0156  # Black Sturgeon River Provincial Park
    set_key CA-0157 VEFF-0157  # Blind River Provincial Park
    set_key CA-0158 VEFF-0158  # Blue Jay Creek Provincial Park
    set_key CA-0159 VEFF-0159  # Blue Lake Provincial Park
    set_key CA-0160 VEFF-0160  # Bon Echo Provincial Park
    set_key CA-0161 VEFF-0161  # Bonheur River Kame Provincial Park
    set_key CA-0162 VEFF-0162  # Bonnechere Provincial Park
    set_key CA-0163 VEFF-0163  # Bonnechere River Provincial Park
    set_key CA-0164 VEFF-0164  # Boyne Valley Provincial Park
    set_key CA-0165 VEFF-0165  # Brightsand River Provincial Park
    set_key CA-0166 VEFF-0166  # Bronte Creek Provincial Park
    set_key CA-0167 VEFF-0167  # Butler Lake Provincial Park
    set_key CA-0168 VEFF-0168  # Cabot Head Provincial Park
    set_key CA-0169 VEFF-0169  # Caliper Lake Provincial Park
    set_key CA-0170 VEFF-0170  # Carden Alvar Provincial Park
    set_key CA-0171 VEFF-0171  # Carson Lake Provincial Park
    set_key CA-0172 VEFF-0172  # Castle Creek Provincial Park
    set_key CA-0173 VEFF-0173  # Cavern Lake Provincial Park
    set_key CA-0175 VEFF-0175  # Centennial Lake Provincial Park
    set_key CA-0176 VEFF-0176  # Chantry Island Migratory Bird Sanctuary
    set_key CA-0177 VEFF-0177  # Chapleau Crown Game Preserve
    set_key CA-0178 VEFF-0178  # Chapleau-Nemegosenda River Provincial Park
    set_key CA-0179 VEFF-0179  # Charleston Lake Provincial Park
    set_key CA-0180 VEFF-0180  # Chiniguchi Waterway Provincial Park
    set_key CA-0181 VEFF-0181  # Chutes Provincial Park
    set_key CA-0182 VEFF-0182  # Clear Creek Forest Provincial Park
    set_key CA-0183 VEFF-0183  # Coral Rapids Provincial Park
    set_key CA-0184 VEFF-0184  # Craigleith Provincial Park
    set_key CA-0185 VEFF-0185  # Craig's Pit Provincial Park
    set_key CA-0186 VEFF-0186  # Cranberry Lake Provincial Park
    set_key CA-0187 VEFF-0187  # Daisy Lake Uplands Provincial Park
    set_key CA-0188 VEFF-0188  # Dana-Jowsey Lakes Provincial Park
    set_key CA-0189 VEFF-0189  # Darlington Provincial Park
    set_key CA-0190 VEFF-0190  # Devils Glen Provincial Park
    set_key CA-0191 VEFF-0191  # Devon Road Mesa Provincial Park
    set_key CA-0192 VEFF-0192  # Divide Ridge Provincial Park
    set_key CA-0193 VEFF-0193  # Dividing Lake Provincial Park
    set_key CA-0194 VEFF-0194  # Driftwood Provincial Park
    set_key CA-0195 VEFF-0195  # Duclos Point Provincial Park
    set_key CA-0196 VEFF-0196  # Duncan Escarpment Provincial Park
    set_key CA-0197 VEFF-0197  # Eagle Dogtooth Provincial Park
    set_key CA-0198 VEFF-0198  # Earl Rowe Provincial Park
    set_key CA-0199 VEFF-0199  # East English River Provincial Park
    set_key CA-0200 VEFF-0200  # East Sister Island Provincial Park
    set_key CA-0201 VEFF-0201  # Edward Island Provincial Park
    set_key CA-0202 VEFF-0202  # Egan Chutes Provincial Park
    set_key CA-0204 VEFF-0204  # Emily Provincial Park
    set_key CA-0205 VEFF-0205  # Englehart River Fine Sand Plain and Waterway Provincial Park
    set_key CA-0206 VEFF-0206  # Esker Lakes Provincial Park
    set_key CA-0207 VEFF-0207  # Fairbank Provincial Park
    set_key CA-0208 VEFF-0208  # Fawn River Provincial Park
    set_key CA-0209 VEFF-0209  # Ferris Provincial Park
    set_key CA-0210 VEFF-0210  # Finlayson Point Provincial Park
    set_key CA-0211 VEFF-0211  # Fish Point Provincial Park
    set_key CA-0212 VEFF-0212  # Fitzroy Provincial Park
    set_key CA-0213 VEFF-0213  # Five Mile Lake Provincial Park
    set_key CA-0214 VEFF-0214  # Forks of the Credit Provincial Park
    set_key CA-0215 VEFF-0215  # Foy Provincial Park
    set_key CA-0216 VEFF-0216  # Fraleigh Lake Provincial Park
    set_key CA-0217 VEFF-0217  # Frederick House Lake Provincial Park
    set_key CA-0218 VEFF-0218  # French River Provincial Park
    set_key CA-0219 VEFF-0219  # Frontenac Provincial Park
    set_key CA-0220 VEFF-0220  # Fushimi Lake Provincial Park
    set_key CA-0221 VEFF-0221  # Gibson River Provincial Park
    set_key CA-0222 VEFF-0222  # Gravel River Provincial Park
    set_key CA-0223 VEFF-0223  # Greenwater Provincial Park
    set_key CA-0224 VEFF-0224  # Grundy Lake Provincial Park
    set_key CA-0225 VEFF-0225  # Halfway Lake Provincial Park
    set_key CA-0226 VEFF-0226  # Hannah Bay Migratory Bird Sanctuary
    set_key CA-0227 VEFF-0227  # Hardy Lake Provincial Park
    set_key CA-0228 VEFF-0228  # Hicks-Oke Bog Provincial Park
    set_key CA-0229 VEFF-0229  # Hockley Valley Provincial Park
    set_key CA-0230 NIL-0000  # Holland Landing; WWFF candidates: VEFF-0230, VEFF-3541
    set_key CA-0231 VEFF-0231  # Hope Bay Forest Provincial Park
    set_key CA-0232 VEFF-0232  # Indian Point Provincial Park
    set_key CA-0233 VEFF-0233  # Inverhuron Provincial Park
    set_key CA-0234 VEFF-0234  # Ipperwash Dunes &amp;amp
    set_key CA-0235 VEFF-0235  # Ira Lake Provincial Park
    set_key CA-0236 VEFF-0236  # Ivanhoe Lake Provincial Park
    set_key CA-0237 VEFF-0237  # J. Albert Bauer Provincial Park
    set_key CA-0238 VEFF-0238  # James N. Allan Provincial Park
    set_key CA-0239 VEFF-0239  # Jocko Rivers Provincial Park
    set_key CA-0240 VEFF-0240  # John E. Pearce Provincial Park
    set_key CA-0241 VEFF-0241  # Johnston Harbour-Pine Tree Point Provincial Park
    set_key CA-0242 VEFF-0242  # Kabitotikwia River Provincial Park
    set_key CA-0243 VEFF-0243  # Kaiashk Provincial Park
    set_key CA-0244 VEFF-0244  # Kakabeka Falls Provincial Park
    set_key CA-0245 VEFF-0245  # Kama Hills Provincial Park
    set_key CA-0246 VEFF-0246  # Kap-Kig-Iwan Provincial Park
    set_key CA-0247 VEFF-0247  # Kashabowie Provincial Park
    set_key CA-0248 VEFF-0248  # Kawartha Highlands Provincial Park
    set_key CA-0249 VEFF-0249  # Kenny Forest Provincial Park
    set_key CA-0250 VEFF-0250  # Kesagami Provincial Park
    set_key CA-0251 VEFF-0251  # Kettle Lakes Provincial Park
    set_key CA-0252 VEFF-0252  # Killarney Provincial Park
    set_key CA-0253 VEFF-0253  # Killarney Lakelands and Headwaters Provincial Park+D2408
    set_key CA-0254 VEFF-0254  # Killbear Provincial Park
    set_key CA-0255 VEFF-0255  # Komoka Provincial Park
    set_key CA-0256 VEFF-0256  # Kopka River Provincial Park
    set_key CA-0257 VEFF-0257  # La Cloche Provincial Park
    set_key CA-0258 VEFF-0258  # La Motte Lake Provincial Park
    set_key CA-0259 VEFF-0259  # La Verendrye Provincial Park
    set_key CA-0260 VEFF-0260  # Lady Evelyn-Smoothwater Provincial Park
    set_key CA-0261 VEFF-0261  # Lake Abitibi Islands Provincial Park
    set_key CA-0262 VEFF-0262  # Lake Nipigon Provincial Park
    set_key CA-0263 VEFF-0263  # Lake of the Woods Provincial Park
    set_key CA-0264 VEFF-0264  # Lake on the Mountain Provincial Park
    set_key CA-0265 VEFF-0265  # Lake St. Peter Provincial Park
    set_key CA-0266 VEFF-0266  # Lake Superior Provincial Park
    set_key CA-0267 VEFF-0267  # Larder River Provincial Park
    set_key CA-0268 VEFF-0268  # Le Pate Provincial Park
    set_key CA-0269 VEFF-0269  # Lighthouse Point Provincial Park
    set_key CA-0270 VEFF-0270  # Limestone Islands Provincial Park
    set_key CA-0271 VEFF-0271  # Lion's Head Provincial Park
    set_key CA-0272 VEFF-0272  # Little Abitibi Provincial Park
    set_key CA-0273 VEFF-0273  # Little Cove Provincial Park
    set_key CA-0274 VEFF-0274  # Little Current River Provincial Park
    set_key CA-0275 VEFF-0275  # Little Greenwater Lake Provincial Park
    set_key CA-0276 VEFF-0276  # Little White River Provincial Park
    set_key CA-0277 VEFF-0277  # Livingstone Point Provincial Park
    set_key CA-0278 VEFF-0278  # Lola Lake Provincial Park
    set_key CA-0279 VEFF-0279  # Long Point Provincial Park
    set_key CA-0280 VEFF-0280  # Lower Madawaska River Provincial Park
    set_key CA-0281 VEFF-0281  # MacGregor Point Provincial Park
    set_key CA-0282 VEFF-0282  # MacLeod Provincial Park
    set_key CA-0283 VEFF-0283  # Magnetawan River Provincial Park
    set_key CA-0284 VEFF-0284  # Makobe-Grays River Provincial Park
    set_key CA-0285 VEFF-0285  # Manitou Islands Provincial Park
    set_key CA-0286 VEFF-0286  # Mara Provincial Park
    set_key CA-0287 VEFF-0287  # Mark S. Burnham Provincial Park
    set_key CA-0288 VEFF-0288  # Marten River Provincial Park
    set_key CA-0289 VEFF-0289  # Mashkinonje Provincial Park
    set_key CA-0290 VEFF-0290  # Massasauga Provincial Park
    set_key CA-0291 VEFF-0291  # Matawatchan Provincial Park
    set_key CA-0292 VEFF-0292  # Matawin River Provincial Park
    set_key CA-0293 VEFF-0293  # Matinenda Provincial Park
    set_key CA-0294 VEFF-0294  # Mattawa River Provincial Park
    set_key CA-0295 VEFF-0295  # Maynard Lake Provincial Park
    set_key CA-0296 VEFF-0296  # McRae Point Provincial Park
    set_key CA-0297 VEFF-0297  # Menzel Centennial Provincial Park
    set_key CA-0298 VEFF-0298  # Michipicoten Island Provincial Park
    set_key CA-0299 VEFF-0299  # Michipicoten Post Provincial Park
    set_key CA-0300 VEFF-0300  # Mikisew Provincial Park
    set_key CA-0301 VEFF-0301  # Minnitaki Kames Provincial Park
    set_key CA-0302 VEFF-0302  # Misery Bay Provincial Park
    set_key CA-0303 VEFF-0303  # Missinaibi Provincial Park
    set_key CA-0304 VEFF-0304  # Mississagi Provincial Park
    set_key CA-0305 VEFF-0305  # Mississagi Delta Provincial Park
    set_key CA-0306 VEFF-0306  # Mississagi River Provincial Park
    set_key CA-0307 VEFF-0307  # Mississippi Lake Migratory Bird Sanctuary
    set_key CA-0308 VEFF-0308  # Mono Cliffs Provincial Park
    set_key CA-0309 VEFF-0309  # Montreal River Provincial Park
    set_key CA-0310 VEFF-0310  # Moose River Migratory Bird Sanctuary
    set_key CA-0311 VEFF-0311  # Morris Tract Provincial Park
    set_key CA-0312 VEFF-0312  # Murphys Point Provincial Park
    set_key CA-0313 VEFF-0313  # Nagagami Lake Provincial Park
    set_key CA-0314 VEFF-0314  # Nagagamisis Provincial Park
    set_key CA-0315 VEFF-0315  # Nakina Moraine Provincial Park
    set_key CA-0316 VEFF-0316  # Neys Provincial Park
    set_key CA-0317 VEFF-0317  # Noganosh Lake Provincial Park
    set_key CA-0318 VEFF-0318  # Noisy River Provincial Park
    set_key CA-0319 VEFF-0319  # North Beach Provincial Park
    set_key CA-0320 VEFF-0320  # North Channel Inshore Provincial Park
    set_key CA-0321 VEFF-0321  # North Driftwood River Provincial Park
    set_key CA-0322 VEFF-0322  # Nottawasaga Lookout Provincial Park
    set_key CA-0323 VEFF-0323  # Oastler Lake Provincial Park
    set_key CA-0324 VEFF-0324  # Obabika River Provincial Park
    set_key CA-0325 VEFF-0325  # Obatanga Provincial Park
    set_key CA-0326 VEFF-0326  # O'Donnell Point Provincial Park
    set_key CA-0327 VEFF-0327  # Ojibway Provincial Park
    set_key CA-0328 VEFF-0328  # Ojibway Prairie Provincial Park
    set_key CA-0329 VEFF-0329  # Opasquia Provincial Park
    set_key CA-0330 VEFF-0330  # Opeongo River Provincial Park
    set_key CA-0331 VEFF-0331  # Otoskwin-Attawapiskat River Provincial Park
    set_key CA-0332 VEFF-0332  # Ottawa River Provincial Park
    set_key CA-0333 VEFF-0333  # Ouimet Canyon Provincial Park
    set_key CA-0334 VEFF-0334  # Oxtongue River-Ragged Falls Provincial Park
    set_key CA-0335 VEFF-0335  # Pakwash Provincial Park
    set_key CA-0336 VEFF-0336  # Pancake Bay Provincial Park
    set_key CA-0337 VEFF-0337  # Pantagruel Creek Provincial Park
    set_key CA-0338 VEFF-0338  # Peter's Woods Provincial Park
    set_key CA-0339 VEFF-0339  # Petroglyphs Provincial Park
    set_key CA-0340 VEFF-0340  # Pichogen River Mixed Forest Provincial Park
    set_key CA-0341 VEFF-0341  # Pigeon River Provincial Park
    set_key CA-0342 VEFF-0342  # Pinery Provincial Park
    set_key CA-0343 VEFF-0343  # Pipestone River Provincial Park
    set_key CA-0344 VEFF-0344  # Point Farms Provincial Park
    set_key CA-0345 VEFF-0345  # Polar Bear Provincial Park
    set_key CA-0346 VEFF-0346  # Porphyry Island Provincial Park
    set_key CA-0347 VEFF-0347  # Port Bruce Provincial Park
    set_key CA-0348 VEFF-0348  # Port Burwell Provincial Park
    set_key CA-0349 VEFF-0349  # Potholes Provincial Park
    set_key CA-0350 VEFF-0350  # Prairie River Mouth Provincial Park
    set_key CA-0351 VEFF-0351  # Presqu'ile Provincial Park
    set_key CA-0352 VEFF-0352  # Pretty River Valley Provincial Park
    set_key CA-0353 VEFF-0353  # Puff Island Provincial Park
    set_key CA-0354 VEFF-0354  # Pukaskwa River Provincial Park
    set_key CA-0355 VEFF-0355  # Pushkin Hills Provincial Park
    set_key CA-0356 VEFF-0356  # Quackenbush Provincial Park
    set_key CA-0357 VEFF-0357  # Queen Elizabeth the Queen Mother Mnidoo Mnising Provincial Park
    set_key CA-0358 VEFF-0358  # Queen Elizabeth II Wildlands Provincial Park
    set_key CA-0359 VEFF-0359  # Quetico Provincial Park
    set_key CA-0360 VEFF-0360  # Rainbow Falls Provincial Park
    set_key CA-0361 VEFF-0361  # Red Sucker Point Provincial Park
    set_key CA-0362 VEFF-0362  # Rene Brunelle Provincial Park
    set_key CA-0363 VEFF-0363  # Restoule Provincial Park
    set_key CA-0364 VEFF-0364  # Rideau Migratory Bird Sanctuary
    set_key CA-0365 VEFF-0365  # Rideau River Provincial Park
    set_key CA-0366 VEFF-0366  # River Aux Sables Provincial Park
    set_key CA-0367 VEFF-0367  # Rock Point Provincial Park
    set_key CA-0368 VEFF-0368  # Rondeau Provincial Park
    set_key CA-0369 VEFF-0369  # Round Lake Provincial Park
    set_key CA-0370 VEFF-0370  # Ruby Lake Provincial Park
    set_key CA-0371 VEFF-0371  # Rushing River Provincial Park
    set_key CA-0372 VEFF-0372  # Sable Islands Provincial Park
    set_key CA-0373 VEFF-0373  # Samuel de Champlain Provincial Park
    set_key CA-0374 VEFF-0374  # Sandbanks Provincial Park
    set_key CA-0375 VEFF-0375  # Sandbar Lake Provincial Park
    set_key CA-0376 VEFF-0376  # Sandpoint Island Provincial Park
    set_key CA-0377 VEFF-0377  # Sandy Islands Provincial Park
    set_key CA-0378 VEFF-0378  # Sauble Falls Provincial Park
    set_key CA-0379 VEFF-0379  # Schreiber Channel Provincial Park
    set_key CA-0380 VEFF-0380  # Sedgman Lake Provincial Park
    set_key CA-0381 VEFF-0381  # Selkirk Provincial Park
    set_key CA-0382 VEFF-0382  # Severn River Provincial Park
    set_key CA-0383 VEFF-0383  # Sextant Rapids Provincial Park
    set_key CA-0384 VEFF-0384  # Shallow River Provincial Park
    set_key CA-0385 VEFF-0385  # Sharbot Lake Provincial Park
    set_key CA-0386 VEFF-0386  # Shesheeb Bay Provincial Park
    set_key CA-0387 VEFF-0387  # Short Hills Provincial Park
    set_key CA-0388 VEFF-0388  # Sibbald Point Provincial Park
    set_key CA-0389 VEFF-0389  # Silent Lake Provincial Park
    set_key CA-0390 VEFF-0390  # Silver Falls Provincial Park
    set_key CA-0391 VEFF-0391  # Silver Lake Provincial Park
    set_key CA-0392 VEFF-0392  # Sioux Narrows Provincial Park
    set_key CA-0393 VEFF-0393  # Six Mile Lake Provincial Park
    set_key CA-0394 VEFF-0394  # Slate Islands Provincial Park
    set_key CA-0395 VEFF-0395  # Sleeping Giant Provincial Park
    set_key CA-0396 VEFF-0396  # Smokey Head-White Bluff Provincial Park
    set_key CA-0397 VEFF-0397  # Solace Provincial Park
    set_key CA-0398 VEFF-0398  # South Bay Provincial Park
    set_key CA-0399 VEFF-0399  # Spanish River Provincial Park
    set_key CA-0400 VEFF-0400  # Springwater Provincial Park
    set_key CA-0401 VEFF-0401  # Spruce Islands Provincial Park
    set_key CA-0402 VEFF-0402  # St. Joseph's Island Migratory Bird Sanctuary
    set_key CA-0403 VEFF-0403  # Steel River Provincial Park
    set_key CA-0404 VEFF-0404  # Stoco Fen Provincial Park
    set_key CA-0405 VEFF-0405  # Strawberry Island Provincial Park
    set_key CA-0406 VEFF-0406  # Sturgeon Bay Provincial Park
    set_key CA-0407 VEFF-0407  # Sturgeon River Provincial Park
    set_key CA-0408 VEFF-0408  # Temagami River Provincial Park
    set_key CA-0409 VEFF-0409  # Thackeray (Thackery) Provincial Park
    set_key CA-0410 VEFF-0410  # The Shoals Provincial Park
    set_key CA-0411 VEFF-0411  # Thompson Island Provincial Park
    set_key CA-0412 VEFF-0412  # Tide Lake Provincial Park
    set_key CA-0413 VEFF-0413  # Tidewater Provincial Park
    set_key CA-0414 VEFF-0414  # Timber Island Provincial Park
    set_key CA-0415 VEFF-0415  # Trillium Woods Provincial Park
    set_key CA-0416 VEFF-0416  # Trout Lake Provincial Park
    set_key CA-0417 VEFF-0417  # Turkey Point Provincial Park
    set_key CA-0418 VEFF-0418  # Turtle River-White Otter Lake Provincial Park
    set_key CA-0419 VEFF-0419  # Upper Canada Migratory Bird Sanctuary
    set_key CA-0420 VEFF-0420  # Upper Madawaska River Provincial Park
    set_key CA-0421 VEFF-0421  # Voyageur Provincial Park
    set_key CA-0422 VEFF-0422  # W.J.B. Greenwood Provincial Park
    set_key CA-0423 VEFF-0423  # Wabakimi Provincial Park
    set_key CA-0424 VEFF-0424  # Wakami Lake Provincial Park
    set_key CA-0425 VEFF-0425  # Wanapitei Provincial Park
    set_key CA-0426 VEFF-0426  # Wasaga Beach Provincial Park
    set_key CA-0427 VEFF-0427  # Waubaushene Beaches Provincial Park
    set_key CA-0428 VEFF-0428  # Wenebegon River Provincial Park
    set_key CA-0429 VEFF-0429  # West Bay Provincial Park
    set_key CA-0430 VEFF-0430  # West English River Provincial Park
    set_key CA-0431 VEFF-0431  # West Montreal River Provincial Park
    set_key CA-0432 VEFF-0432  # West Sandy Island Provincial Park
    set_key CA-0433 VEFF-0433  # Westmeath Provincial Park
    set_key CA-0434 VEFF-0434  # Wheatley Provincial Park
    set_key CA-0435 VEFF-0435  # White Lake Provincial Park
    set_key CA-0436 VEFF-0436  # Williams Island Provincial Park
    set_key CA-0437 VEFF-0437  # Windigo Bay Provincial Park
    set_key CA-0438 VEFF-0438  # Windigo Point Provincial Park
    set_key CA-0439 VEFF-0439  # Windy Lake Provincial Park
    set_key CA-0440 VEFF-0440  # Winisk River Provincial Park
    set_key CA-0441 VEFF-0441  # Winnange Lake Provincial Park
    set_key CA-0442 VEFF-0442  # Wolf Island Provincial Park
    set_key CA-0443 VEFF-0443  # Woman River Forest Provincial Park
    set_key CA-0444 VEFF-0444  # Woodland Caribou Provincial Park
    set_key CA-0445 VEFF-0445  # Cultus Lake Provincial Park
    set_key CA-0446 VEFF-0446  # Parc National du Mont-Mégantic
    set_key CA-0447 VEFF-0447  # Herring Cove Provincial Park
    set_key CA-0448 VEFF-0448  # Roosevelt Campobello International Park
    set_key CA-0449 VEFF-0449  # Amherst Shore Provincial Park
    set_key CA-0450 VEFF-0450  # Arisaig Provincial Park
    set_key CA-0451 VEFF-0451  # Blomidon Provincial Park
    set_key CA-0452 VEFF-0452  # Boylston Provincial Park
    set_key CA-0453 VEFF-0453  # Bras d'Or Lake Biosphere Reserve Area
    set_key CA-0454 VEFF-0454  # Cabots Landing Provincial Park
    set_key CA-0455 VEFF-0455  # Cape Chignecto Provincial Park
    set_key CA-0456 VEFF-0456  # Cape Smokey Provincial Park
    set_key CA-0457 VEFF-0457  # Cape Split Provincial Park
    set_key CA-0458 VEFF-0458  # Crystal Crescent Beach Provincial Park
    set_key CA-0459 VEFF-0459  # Dominion Beach Provincial Park
    set_key CA-0460 VEFF-0460  # Five Islands Provincial Park
    set_key CA-0461 VEFF-0461  # Fort Point Lighthouse Park
    set_key CA-0462 VEFF-0462  # Graves Island Provincial Park
    set_key CA-0463 VEFF-0463  # Herring Cove Provincial Park Reserve
    set_key CA-0464 VEFF-0464  # Jerry Lawrence Provincial Park
    set_key CA-0465 VEFF-0465  # Lawrencetown Beach Provincial Park
    set_key CA-0466 VEFF-0466  # Martinique Beach Provincial Park
    set_key CA-0467 VEFF-0467  # Mavillette Beach Provincial Park
    set_key CA-0468 VEFF-0468  # McNabs and Lawlor Islands Provincial Park
    set_key CA-0469 VEFF-0469  # Melmerby Beach Provincial Park
    set_key CA-0470 VEFF-0470  # North River Provincial Park
    set_key CA-0471 VEFF-0471  # Oakfield Provincial Park
    set_key CA-0472 VEFF-0472  # Petersfield Provincial Park
    set_key CA-0473 VEFF-0473  # Pomquet Beach Provincial Park
    set_key CA-0474 VEFF-0474  # Rushton's Beach Provincial Park
    set_key CA-0475 VEFF-0475  # Sackville Lakes Provincial Park
    set_key CA-0476 VEFF-0476  # Salt Springs Provincial Park
    set_key CA-0477 VEFF-0477  # Sand Hills Beach Provincial Park
    set_key CA-0478 VEFF-0478  # Scots Bay Provincial Park
    set_key CA-0479 VEFF-0479  # Sherbrooke Provincial Park
    set_key CA-0480 VEFF-0480  # Summerville Beach Provincial Park
    set_key CA-0481 VEFF-0481  # Taylor Head Provincial Park
    set_key CA-0482 VEFF-0482  # The Islands Provincial Park
    set_key CA-0483 VEFF-0483  # Thomas Raddall Provincial Park
    set_key CA-0484 VEFF-0484  # Tor Bay Provincial Park
    set_key CA-0485 VEFF-0485  # Trout Brook Provincial Park
    set_key CA-0486 VEFF-0486  # Usige Ban Falls Provincial Park
    set_key CA-0487 VEFF-0487  # Valleyview Provincial Park
    set_key CA-0488 VEFF-0488  # Waterside Beach Provincial Park
    set_key CA-0489 VEFF-0489  # Wentzells Lake Provincial Park
    set_key CA-0490 VEFF-0490  # West Mabou Beach Provincial Park
    set_key CA-0491 VEFF-0491  # Aiguebelle
    set_key CA-0492 VEFF-0492  # Bic
    set_key CA-0493 VEFF-0493  # Bois de l'Ile Bizard
    set_key CA-0494 VEFF-0494  # Bois-de-Liesse
    set_key CA-0495 VEFF-0495  # Fjord-du-Saguenay
    set_key CA-0496 VEFF-0496  # Frontenac National Park
    set_key CA-0497 VEFF-0497  # Gaspesie National Park
    set_key CA-0498 VEFF-0498  # Gatineau National Park
    set_key CA-0499 VEFF-0499  # Grands-Jardins
    set_key CA-0500 VEFF-0500  # Hautes-Gorges-de-la-Riviere-Malbaie
    set_key CA-0501 VEFF-0501  # Iles-de-Boucherville
    set_key CA-0502 VEFF-0502  # Jacques-Cartier
    set_key CA-0503 VEFF-0503  # Jacques Cartier Gatineau
    set_key CA-0504 VEFF-0504  # Kuururjuaq
    set_key CA-0505 VEFF-0505  # Lac-Témiscouata
    set_key CA-0506 VEFF-0506  # Miguasha
    set_key CA-0507 VEFF-0507  # Mont-Orford
    set_key CA-0508 VEFF-0508  # Mont-Saint-Bruno
    set_key CA-0509 VEFF-0509  # Mont-Tremblant
    set_key CA-0510 VEFF-0510  # Monts-Valin
    set_key CA-0511 VEFF-0511  # Mount Royal
    set_key CA-0512 VEFF-0512  # Oka
    set_key CA-0513 VEFF-0513  # Opemican
    set_key CA-0514 VEFF-0514  # Parc de I'Ile-Charron
    set_key CA-0515 VEFF-0515  # Parc de la Chute-Montmorency
    set_key CA-0516 VEFF-0516  # Pingualuit
    set_key CA-0517 VEFF-0517  # Plaisance
    set_key CA-0518 VEFF-0518  # Pointe-Taillon
    set_key CA-0519 VEFF-0519  # Tursujuq
    set_key CA-0520 VEFF-0520  # Yamaska
    set_key CA-0521 VEFF-0521  # Amisk Park Reserve
    set_key CA-0522 VEFF-0522  # Asessippi Provincial Park
    set_key CA-0523 VEFF-0523  # Atikaki Provincial Wilderness Park
    set_key CA-0524 VEFF-0524  # Bakers Narrows Provincial Park
    set_key CA-0525 VEFF-0525  # Beaudry Provincial Park
    set_key CA-0526 VEFF-0526  # Beaver Creek Provincial Park
    set_key CA-0527 VEFF-0527  # Birch Island Provincial Park
    set_key CA-0528 VEFF-0528  # Birch Point Provincial Park
    set_key CA-0529 VEFF-0529  # Birds Hill Provincial Park
    set_key CA-0530 VEFF-0530  # Burge Lake Provincial Park
    set_key CA-0531 VEFF-0531  # Camp Morton Provincial Park
    set_key CA-0532 VEFF-0532  # Caribou River Provincial Park
    set_key CA-0533 VEFF-0533  # Chitek Lake Anishinaabe Provincial Park
    set_key CA-0534 VEFF-0534  # Clearwater Lake Provincial Park
    set_key CA-0535 VEFF-0535  # Colvin Lake Provincial Park
    set_key CA-0536 VEFF-0536  # Criddle / Vane Homestead Provincial Park
    set_key CA-0538 VEFF-0538  # Duck Mountain Provincial Park
    set_key CA-0539 VEFF-0539  # Duff Roblin Provincial Park
    set_key CA-0540 VEFF-0540  # Elk Island Provincial Park
    set_key CA-0541 VEFF-0541  # Fisher Bay Provincial Park
    set_key CA-0542 VEFF-0542  # Goose Islands Park Reserve
    set_key CA-0543 VEFF-0543  # Grand Beach Provincial Park
    set_key CA-0544 VEFF-0544  # Grand Island Park Reserve
    set_key CA-0545 VEFF-0545  # Grass River Provincial Park
    set_key CA-0546 VEFF-0546  # Hecla / Grindstone Provincial Park
    set_key CA-0547 VEFF-0547  # Kettle Stones Provincial Park
    set_key CA-0548 VEFF-0548  # Kinwow Bay Provincial Park
    set_key CA-0549 VEFF-0549  # Little Limestone Lake Provincial Park
    set_key CA-0550 VEFF-0550  # Lockport Provincial Heritage Park
    set_key CA-0551 VEFF-0551  # Manigotagan River Provincial Park
    set_key CA-0552 VEFF-0552  # Manipogo Provincial Park
    set_key CA-0553 VEFF-0553  # Marchand Provincial Park
    set_key CA-0554 VEFF-0554  # Memorial Provincial Park
    set_key CA-0555 VEFF-0555  # Moose Lake Provincial Park
    set_key CA-0556 VEFF-0556  # Nopiming Provincial Park
    set_key CA-0557 VEFF-0557  # Norris Lake Provincial Park
    set_key CA-0558 VEFF-0558  # North Steeprock Lake Provincial Park
    set_key CA-0559 VEFF-0559  # Nueltin Lake Provincial Park
    set_key CA-0560 VEFF-0560  # Numaykoos Lake Provincial Park
    set_key CA-0561 VEFF-0561  # Paint Lake Provincial Park
    set_key CA-0562 VEFF-0562  # Patricia Beach Provincial Park
    set_key CA-0563 VEFF-0563  # Pisew Falls Provincial Park
    set_key CA-0564 VEFF-0564  # River Road Provincial Park
    set_key CA-0565 VEFF-0565  # Rivers Provincial Park
    set_key CA-0566 VEFF-0566  # South Atikaki Provincial Park
    set_key CA-0567 VEFF-0567  # Spruce Woods Provincial Park
    set_key CA-0568 VEFF-0568  # St. Norbert Provincial Park
    set_key CA-0569 VEFF-0569  # Stephenfield Provincial Park
    set_key CA-0570 VEFF-0570  # Trappist Monastery Provincial Park
    set_key CA-0571 VEFF-0571  # Turtle Mountain Provincial Park
    set_key CA-0572 VEFF-0572  # Whittier Park Provincial Park
    set_key CA-0573 VEFF-0573  # William Lake Provincial Park
    set_key CA-0574 VEFF-0574  # Amisk Lake Recreation Site
    set_key CA-0575 VEFF-0575  # Arm River Recreation Site
    set_key CA-0576 VEFF-0576  # Armit River Recreation Site
    set_key CA-0577 VEFF-0577  # Athabasca Sand Dunes Provincial Park
    set_key CA-0578 VEFF-0578  # Beaupre Creek Recreation Site
    set_key CA-0579 VEFF-0579  # Beatty Lake Recreation Site
    set_key CA-0580 VEFF-0580  # Big Sandy Lake Recreation Site
    set_key CA-0581 VEFF-0581  # Blackstrap Provincial Park
    set_key CA-0582 VEFF-0582  # Brockelbank Hill Park Reserve
    set_key CA-0583 VEFF-0583  # Bronson Forest Recreation Site
    set_key CA-0584 VEFF-0584  # Buffalo Pound Provincial Park
    set_key CA-0585 VEFF-0585  # Candle Lake Provincial Park
    set_key CA-0586 VEFF-0586  # Cannington Manor Provincial Park
    set_key CA-0587 NIL-0000  # Chitek Lake Recreation Site; WWFF candidates: VEFF-0587, VEFF-4194
    set_key CA-0588 VEFF-0588  # Clarence-Steepbank Lakes Provincial Park
    set_key CA-0589 VEFF-0589  # Clearwater River Provincial Park
    set_key CA-0590 VEFF-0590  # Crooked Lake Provincial Park
    set_key CA-0591 VEFF-0591  # Cumberland House Provincial Park
    set_key CA-0592 VEFF-0592  # Cypress Hills Interprovincial Park
    set_key CA-0593 VEFF-0593  # Danielson Provincial Park
    set_key CA-0594 VEFF-0594  # Delaronde Lake (Zig Zag Bay) Recreation Site
    set_key CA-0595 VEFF-0595  # Douglas Provincial Park
    set_key CA-0596 VEFF-0596  # Duck Mountain Provincial Park
    set_key CA-0597 VEFF-0597  # Echo Valley Provincial Park
    set_key CA-0598 VEFF-0598  # Fowler Lake Recreation Site
    set_key CA-0599 VEFF-0599  # Fort Carlton Provincial Park
    set_key CA-0600 VEFF-0600  # Fort Pitt Provincial Park
    set_key CA-0601 VEFF-0601  # Fur Lake Recreation Site
    set_key CA-0602 VEFF-0602  # Good Spirit Lake Provincial Park
    set_key CA-0603 VEFF-0603  # Great Blue Heron Provincial Park
    set_key CA-0604 VEFF-0604  # Greenwater Lake Provincial Park
    set_key CA-0605 VEFF-0605  # Hanson Lake Recreation Site
    set_key CA-0606 VEFF-0606  # Island Lake Recreation Site
    set_key CA-0607 VEFF-0607  # Jan Lake Recreation Site
    set_key CA-0608 VEFF-0608  # Katepwa Point Provincial Park
    set_key CA-0609 VEFF-0609  # Lac La Ronge Provincial Park
    set_key CA-0610 VEFF-0610  # Last Mountain House Provincial Park
    set_key CA-0611 VEFF-0611  # Little Bear Lake Recreation Site
    set_key CA-0612 VEFF-0612  # Makwa Lake Provincial Park
    set_key CA-0613 VEFF-0613  # Meadow Lake Provincial Park
    set_key CA-0614 VEFF-0614  # Moose Mountain Provincial Park
    set_key CA-0615 VEFF-0615  # Motherwell Homestead National Historic Site
    set_key CA-0616 VEFF-0616  # Narrow Hills Provincial Park
    set_key CA-0617 VEFF-0617  # Pagan Lake Recreation Site
    set_key CA-0618 VEFF-0618  # Parr Hill Lake Recreation Site
    set_key CA-0619 VEFF-0619  # Pike Lake Provincial Park
    set_key CA-0620 VEFF-0620  # Quill Lakes Park Reserve
    set_key CA-0621 VEFF-0621  # Regina Beach Recreation Site
    set_key CA-0622 VEFF-0622  # Rowan's Ravine Provincial Park
    set_key CA-0623 VEFF-0623  # Saskatchewan Landing Provincial Park
    set_key CA-0624 VEFF-0624  # Steele Narrows Provincial Park
    set_key CA-0625 VEFF-0625  # St. Victor Petroglyphs Provincial Park
    set_key CA-0626 VEFF-0626  # The Battlefords Provincial Park
    set_key CA-0627 VEFF-0627  # Tobin Lake Recreation Site
    set_key CA-0628 VEFF-0628  # Touchwood Hills Post Provincial Park
    set_key CA-0629 VEFF-0629  # Wildcat Hill Provincial Park
    set_key CA-0630 VEFF-0630  # Wood Mountain Post Provincial Park
    set_key CA-0631 VEFF-0631  # Antelope Hill Provincial Park
    set_key CA-0632 VEFF-0632  # Beauvais Lake Provincial Park
    set_key CA-0633 VEFF-0633  # Big Hill Springs Provincial Park
    set_key CA-0634 VEFF-0634  # Big Knife Provincial Park
    set_key CA-0635 VEFF-0635  # Birch Mountains Wildland Provincial Park
    set_key CA-0636 VEFF-0636  # Bow Valley Provincial Park
    set_key CA-0637 VEFF-0637  # Bragg Creek Provincial Park
    set_key CA-0638 VEFF-0638  # Brown-Lowery Provincial Park
    set_key CA-0639 VEFF-0639  # Calling Lake Provincial Park
    set_key CA-0640 VEFF-0640  # Carson-Pegasus Provincial Park
    set_key CA-0641 VEFF-0641  # Crimson Lake Provincial Park
    set_key CA-0642 VEFF-0642  # Cypress Hills Provincial Park
    set_key CA-0643 VEFF-0643  # Dillberry Lake Provincial Park
    set_key CA-0644 VEFF-0644  # Dunvegan Provincial Park
    set_key CA-0645 VEFF-0645  # Dry Island Buffalo Jump Provincial Park
    set_key CA-0646 VEFF-0646  # Eagle Point Provincial Park
    set_key CA-0647 VEFF-0647  # Elbow River Provincial Recreation Area
    set_key CA-0648 VEFF-0648  # Fish Creek Provincial Park
    set_key CA-0649 VEFF-0649  # Glenbow Ranch Provincial Park
    set_key CA-0650 VEFF-0650  # Gooseberry Provincial Recreation Area
    set_key CA-0651 VEFF-0651  # Greene Valley Provincial Park
    set_key CA-0652 VEFF-0652  # Gregoire Lake Provincial Park
    set_key CA-0653 VEFF-0653  # Hilliard's Bay Provincial Park
    set_key CA-0654 VEFF-0654  # Lakeland Provincial Park
    set_key CA-0655 VEFF-0655  # Long Lake Provincial Park
    set_key CA-0656 VEFF-0656  # McLean Creek Provincial Recreation Area
    set_key CA-0657 VEFF-0657  # Midland Provincial Park
    set_key CA-0658 VEFF-0658  # Miquelon Lake Provincial Park
    set_key CA-0659 VEFF-0659  # Moonshine Lake Provincial Park
    set_key CA-0660 VEFF-0660  # Moose Lake Provincial Park
    set_key CA-0661 VEFF-0661  # Notikewin Provincial Park
    set_key CA-0662 VEFF-0662  # Obed Lake Provincial Park
    set_key CA-0663 VEFF-0663  # Peace-Athabasca Delta Natural Area
    set_key CA-0664 VEFF-0664  # Peter Lougheed Provincial Park
    set_key CA-0665 VEFF-0665  # Pierre Grey's Lakes Provincial Park
    set_key CA-0666 VEFF-0666  # Police Outpost Provincial Park
    set_key CA-0667 VEFF-0667  # Ram Falls Provincial Park
    set_key CA-0668 VEFF-0668  # Ribstone Creek Heritage Rangeland Natural Area
    set_key CA-0669 VEFF-0669  # Rock Lake Provincial Park
    set_key CA-0670 VEFF-0670  # Ross Lake Natural Area
    set_key CA-0671 VEFF-0671  # Rumsey Natural Area
    set_key CA-0672 VEFF-0672  # Saskatoon Island Provincial Park
    set_key CA-0673 VEFF-0673  # Scalp Creek Natural Area
    set_key CA-0674 VEFF-0674  # Sheep River Provincial Park
    set_key CA-0675 VEFF-0675  # Sherwood Park Natural Area
    set_key CA-0676 VEFF-0676  # Sir Winston Churchill Park
    set_key CA-0677 VEFF-0677  # Spray Valley Provincial Park
    set_key CA-0678 VEFF-0678  # Sundance Provincial Park
    set_key CA-0679 VEFF-0679  # Tawatinaw Natural Area
    set_key CA-0680 VEFF-0680  # Tolman Badlands Heritage Rangeland Natural Area
    set_key CA-0681 VEFF-0681  # Two Lakes Provincial Park
    set_key CA-0682 VEFF-0682  # Vermilion Provincial Park
    set_key CA-0683 VEFF-0683  # Victoria Settlement Natural Area
    set_key CA-0684 VEFF-0684  # Washout Creek Natural Area
    set_key CA-0685 VEFF-0685  # West Bragg Creek Provincial Recreation Area
    set_key CA-0686 VEFF-0686  # Whitney Lakes Provincial Park
    set_key CA-0687 VEFF-0687  # William A. Switzer Provincial Park
    set_key CA-0688 VEFF-0688  # Winagami Lake Provincial Park
    set_key CA-0689 VEFF-0689  # Writing-on-Stone Provincial Park
    set_key CA-0690 VEFF-0690  # Young's Point Provincial Park
    set_key CA-0691 VEFF-0691  # Akamina-Kishinena Provincial Park
    set_key CA-0692 VEFF-0692  # Alexandra Bridge Provincial Park
    set_key CA-0693 VEFF-0693  # Alice Lake Provincial Park
    set_key CA-0694 VEFF-0694  # Allison Lake Provincial Park
    set_key CA-0695 VEFF-0695  # Anderson Bay Provincial Park
    set_key CA-0696 VEFF-0696  # Anderson Flats Provincial Park
    set_key CA-0697 VEFF-0697  # Anstey Hunakwa Provincial Park
    set_key CA-0698 VEFF-0698  # Arrowstone Provincial Park
    set_key CA-0699 VEFF-0699  # Artlish Caves Provincial Park
    set_key CA-0700 VEFF-0700  # Atna River Provincial Park
    set_key CA-0701 VEFF-0701  # Babine Mountains Provincial Park
    set_key CA-0702 VEFF-0702  # Bamberton Provincial Park
    set_key CA-0703 VEFF-0703  # Banana Island Provincial Park
    set_key CA-0704 VEFF-0704  # Bear Creek Provincial Park
    set_key CA-0705 VEFF-0705  # Bear Glacier Provincial Park
    set_key CA-0706 VEFF-0706  # Big Creek Provincial Park
    set_key CA-0707 VEFF-0707  # Birkenhead Lake Provincial Park
    set_key CA-0708 VEFF-0708  # Bonaparte Provincial Park
    set_key CA-0709 VEFF-0709  # Bowron Lake Provincial Park
    set_key CA-0710 VEFF-0710  # Bugaboo Provincial Park
    set_key CA-0711 VEFF-0711  # Cape Scott Provincial Park
    set_key CA-0712 VEFF-0712  # Cariboo Mountains Provincial Park
    set_key CA-0713 VEFF-0713  # Carp Lake Provincial Park and Protected Area
    set_key CA-0714 VEFF-0714  # Cathedral Provincial Park
    set_key CA-0715 VEFF-0715  # Chase Provincial Park
    set_key CA-0716 VEFF-0716  # Cypress Provincial Park
    set_key CA-0717 VEFF-0717  # Denetiah Provincial Park
    set_key CA-0718 VEFF-0718  # Duffey Lake Provincial Park
    set_key CA-0719 VEFF-0719  # Elk Lakes Provincial Park
    set_key CA-0720 VEFF-0720  # Entiako Provincial Park
    set_key CA-0721 VEFF-0721  # Finger-Tatuk Provincial Park
    set_key CA-0722 VEFF-0722  # Fraser River Provincial Park
    set_key CA-0723 VEFF-0723  # Garibaldi Provincial Park
    set_key CA-0724 VEFF-0724  # Goldstream Provincial Park
    set_key CA-0725 VEFF-0725  # Graystokes Provincial Park
    set_key CA-0726 VEFF-0726  # Height of the Rockies Provincial Park
    set_key CA-0727 VEFF-0727  # Hesquiat Peninsula Provincial Park
    set_key CA-0728 VEFF-0728  # Kalamalka Lake Provincial Park
    set_key CA-0729 VEFF-0729  # Kianuko Provincial Park
    set_key CA-0730 VEFF-0730  # Lava Forks Provincial Park
    set_key CA-0731 VEFF-0731  # Monashee Provincial Park
    set_key CA-0732 VEFF-0732  # Mount Pope Provincial Park
    set_key CA-0733 VEFF-0733  # Northern Rocky Mountains Provincial Park
    set_key CA-0734 VEFF-0734  # Raft Cove Provincial Park
    set_key CA-0735 VEFF-0735  # Rubyrock Lake Provincial Park
    set_key CA-0736 VEFF-0736  # Skagit Valley Provincial Park
    set_key CA-0737 VEFF-0737  # Spatsizi Plateau Wilderness Provincial Park
    set_key CA-0738 VEFF-0738  # Strathcona-Westmin Provincial Park
    set_key CA-0739 VEFF-0739  # Swan Lake/Kispiox River Provincial Park
    set_key CA-0740 VEFF-0740  # Sydney Inlet Provincial Park
    set_key CA-0741 VEFF-0741  # Tahsish-Kwois Provincial Park
    set_key CA-0742 VEFF-0742  # Tatshenshini-Alsek Provincial Park
    set_key CA-0743 VEFF-0743  # Ts'yl-os Provincial Park
    set_key CA-0744 VEFF-0744  # Uncha Mountain Red Hills Provincial Park
    set_key CA-0745 VEFF-0745  # Upper Lillooet Provincial Park
    set_key CA-0746 VEFF-0746  # Vargas Island Provincial Park
    set_key CA-0747 VEFF-0747  # Wapiti Lake Provincial Park
    set_key CA-0748 VEFF-0748  # West Twin Provincial Park
    set_key CA-0749 VEFF-0749  # Woss Lake Provincial Park
    set_key CA-0750 VEFF-0750  # Yahk Provincial Park
    set_key CA-0751 VEFF-0751  # Blackstone Territorial Park
    set_key CA-0752 VEFF-0752  # Cameron Falls Trail
    set_key CA-0753 VEFF-0753  # Chan Lake Territorial Park
    set_key CA-0754 VEFF-0754  # Fort Simpson Territorial Park
    set_key CA-0755 VEFF-0755  # Fred Henne Territorial Park
    set_key CA-0756 VEFF-0756  # Hay River Territorial Park
    set_key CA-0757 VEFF-0757  # Hidden Lake Territorial Park
    set_key CA-0758 VEFF-0758  # Jak Territorial Park
    set_key CA-0759 VEFF-0759  # Lady Evelyn Falls Territorial Park
    set_key CA-0760 VEFF-0760  # Madeline Lake Territorial Park
    set_key CA-0761 VEFF-0761  # Nitainlaii Territorial Park
    set_key CA-0762 VEFF-0762  # Prelude Lake Territorial Park
    set_key CA-0763 VEFF-0763  # Queen Elizabeth Territorial Park
    set_key CA-0764 VEFF-0764  # Reid Lake Territorial Park
    set_key CA-0765 VEFF-0765  # Twin Falls Gorge Territorial Park
    set_key CA-0766 VEFF-0766  # Baillie Settlement Natural Area
    set_key CA-0767 VEFF-0767  # Bay du Vin Island Natural Area
    set_key CA-0768 VEFF-0768  # Blue Mountain Natural Area
    set_key CA-0769 VEFF-0769  # Canoose Flowage Natural Area
    set_key CA-0770 VEFF-0770  # Clark Point Natural Area
    set_key CA-0771 VEFF-0771  # De la Republique Provincial Park
    set_key CA-0772 VEFF-0772  # East Branch Portage River Natural Area
    set_key CA-0774 VEFF-0774  # Freeze Lakes Natural Area
    set_key CA-0775 VEFF-0775  # Glenwood Provincial Park
    set_key CA-0776 VEFF-0776  # Hole-in-the-Wall Provincial Park
    set_key CA-0777 VEFF-0777  # Hopewell Rocks Provincial Park
    set_key CA-0778 VEFF-0778  # Ile-Aux-Foins (Hay Island) Provincial Park
    set_key CA-0779 VEFF-0779  # Jacquet River Gorge Natural Area
    set_key CA-0780 VEFF-0780  # Kennedy Lakes Natural Area
    set_key CA-0781 VEFF-0781  # Lake George Provincial Park
    set_key CA-0782 VEFF-0782  # Lakeside Provincial Park
    set_key CA-0783 VEFF-0783  # MacNichol-Orser Conservation Easement Natural Area
    set_key CA-0784 VEFF-0784  # Mactaquac Provincial Park
    set_key CA-0785 VEFF-0785  # Mary's Point Natural Area
    set_key CA-0786 VEFF-0786  # Meredith Houseworth Memorial Seashore Natural Area
    set_key CA-0787 VEFF-0787  # Middle Island Provincial Park
    set_key CA-0788 VEFF-0788  # Mount Carleton Provincial Park
    set_key CA-0789 VEFF-0789  # Murray Beach Provincial Park
    set_key CA-0790 VEFF-0790  # New River Beach Provincial Park
    set_key CA-0791 VEFF-0791  # Oak Bay Provincial Park
    set_key CA-0792 VEFF-0792  # Parlee Beach Provincial Park
    set_key CA-0793 VEFF-0793  # Saint Croix Island International Park National Historic Site
    set_key CA-0794 VEFF-0794  # Shea Lake Nature Preserve
    set_key CA-0795 VEFF-0795  # Spednic Lake Provincial Park
    set_key CA-0796 VEFF-0796  # Sugarloaf Provincial Park
    set_key CA-0797 VEFF-0797  # Tetagouche Falls Provincial Park
    set_key CA-0798 VEFF-0798  # The Anchorage Provincial Park
    set_key CA-0799 VEFF-0799  # Woolastook Provincial Park
    set_key CA-0800 VEFF-0800  # Youghall Beach Provincial Park
    set_key CA-0801 VEFF-0801  # Arches Provincial Park
    set_key CA-0802 VEFF-0802  # Barachois Pond Provincial Park
    set_key CA-0803 VEFF-0803  # Bellevue Beach Provincial Park
    set_key CA-0804 VEFF-0804  # Blow Me Down Provincial Park
    set_key CA-0805 VEFF-0805  # Butter Pot Provincial Park
    set_key CA-0806 VEFF-0806  # Cataracts Provincial Park
    set_key CA-0807 VEFF-0807  # Chance Cove Provincial Park
    set_key CA-0808 VEFF-0808  # Codroy Valley Provincial Park
    set_key CA-0809 VEFF-0809  # Dildo Run Provincial Park
    set_key CA-0810 VEFF-0810  # Duley Lake Provincial Park
    set_key CA-0811 VEFF-0811  # Dungeon Provincial Park
    set_key CA-0812 VEFF-0812  # Fitzgerald's Pond Provincial Park
    set_key CA-0813 VEFF-0813  # Flatwater Pond Provincial Park
    set_key CA-0814 VEFF-0814  # Frenchman's Cove Provincial Park
    set_key CA-0815 VEFF-0815  # Gooseberry Cove Provincial Park
    set_key CA-0816 VEFF-0816  # Jack's Pond Provincial Park
    set_key CA-0817 VEFF-0817  # Jipujijkuei Kuespem Provincial Park
    set_key CA-0818 VEFF-0818  # Jonathan's Pond Provincial Park
    set_key CA-0819 VEFF-0819  # J. T. Cheeseman Provincial Park
    set_key CA-0820 VEFF-0820  # La Manche Provincial Park
    set_key CA-0821 VEFF-0821  # Lockston Path Provincial Park
    set_key CA-0822 VEFF-0822  # Marine Drive Provincial Park
    set_key CA-0823 VEFF-0823  # Mealy Mountains / Akami-uapishku-KakKasuak Reserve Biosphere
    set_key CA-0824 VEFF-0824  # Notre Dame Provincial Park
    set_key CA-0825 VEFF-0825  # Pinware River Provincial Park
    set_key CA-0826 VEFF-0826  # Pistolet Bay Provincial Park
    set_key CA-0827 VEFF-0827  # Sandbanks Provincial Park
    set_key CA-0828 VEFF-0828  # Sir Richard Squires Memorial Provincial Park
    set_key CA-0829 VEFF-0829  # West Brook Park Reserve Biosphere Reserve
    set_key CA-0830 VEFF-0830  # Windmill Bight Provincial Park
    set_key CA-0831 VEFF-0831  # Inuujarvik Territorial Park
    set_key CA-0832 VEFF-0832  # Iqalugaarjuup Nunanga Territorial Park
    set_key CA-0833 VEFF-0834  # Katannilik Territorial Park
    set_key CA-0834 VEFF-0834  # Kekerten Territorial Historic Park
    set_key CA-0835 VEFF-0835  # Kugluk (Bloody Falls) Territorial Park
    set_key CA-0836 VEFF-0836  # Mallikjuaq Island Territorial Park
    set_key CA-0837 VEFF-0837  # Ovayok Territorial Park
    set_key CA-0838 VEFF-0838  # Pisuktinu Tunngavik Territorial Park
    set_key CA-0839 VEFF-0839  # Qaummaarviit Territorial Historic Park
    set_key CA-0840 VEFF-0840  # Sylvia Grinnell Territorial Park
    set_key CA-0841 VEFF-0841  # Agay Mene Territorial Park
    set_key CA-0842 VEFF-0842  # Asi Keyi Territorial Park
    set_key CA-0843 VEFF-0843  # Coal River Springs Territorial Park
    set_key CA-0844 VEFF-0844  # Five Finger Rapids Territorial Park
    set_key CA-0845 VEFF-0845  # Five Mile Lake Territorial Park
    set_key CA-0846 VEFF-0846  # Herschel Island - Qikiqtaruk Territorial Park
    set_key CA-0847 VEFF-0847  # Kusawa Territorial Park
    set_key CA-0848 VEFF-0848  # Pickhandle Lake Territorial Park
    set_key CA-0849 VEFF-2320  # Tagish River Habitat Protection Area
    set_key CA-0850 VEFF-0850  # Tatchun Lake Territorial Park
    set_key CA-0851 VEFF-0851  # Argyle Shore Provincial Park
    set_key CA-0852 VEFF-0852  # Basin Head Provincial Park
    set_key CA-0853 VEFF-0853  # Belmont Provincial Park
    set_key CA-0854 VEFF-0854  # Bloomfield Provincial Park
    set_key CA-0855 VEFF-0855  # Bonshaw Hills Provincial Park
    set_key CA-0856 VEFF-0856  # Mark Arendz Provincial Ski Park (ex-Brookvale) Provincial Park
    set_key CA-0857 VEFF-0857  # Brudenell River Provincial Park
    set_key CA-0858 VEFF-0858  # Cabot Beach Provincial Park
    set_key CA-0859 VEFF-0859  # Cedar Dunes Provincial Park
    set_key CA-0860 VEFF-0860  # Chelton Beach Provincial Park
    set_key CA-0861 VEFF-0861  # Green Park Provincial Park
    set_key CA-0862 VEFF-0862  # Jacques Cartier Provincial Park
    set_key CA-0863 VEFF-0863  # Kings Castle Provincial Park
    set_key CA-0865 VEFF-0865  # Linkletter Provincial Park
    set_key CA-0867 VEFF-0867  # Malpeque Bay Provincial Park
    set_key CA-0869 VEFF-0869  # Northumberland Provincial Park
    set_key CA-0870 VEFF-0870  # Panmure Island Provincial Park
    set_key CA-0871 VEFF-0871  # Pinette Provincial Park
    set_key CA-0873 VEFF-0873  # Poverty Beach Sand Dunes Natural Area
    set_key CA-0874 VEFF-0874  # Red Point Provincial Park
    set_key CA-0875 VEFF-0875  # Sally's Beach Provincial Park
    set_key CA-0876 VEFF-0876  # Souris Beach Provincial Park
    set_key CA-0877 VEFF-0877  # Strathgartney Provincial Park
    set_key CA-0878 VEFF-0878  # Tea Hill Park Provincial Park
    set_key CA-0879 VEFF-0879  # Union Corner Provincial Park
    set_key CA-0880 VEFF-0880  # Wood Islands Provincial Park
    set_key CA-0881 VEFF-0881  # Annapolis Basin Look Off Provincial Park
    set_key CA-0882 VEFF-0882  # Balmoral Mills Provincial Park
    set_key CA-0883 VEFF-0883  # Battery Provincial Park
    set_key CA-0884 VEFF-0884  # Bayfield Beach Provincial Park
    set_key CA-0885 VEFF-0885  # Bayswater Beach Provincial Park
    set_key CA-0886 VEFF-0886  # Beaver Mountain Provincial Park
    set_key CA-0887 VEFF-0887  # Bell Provincial Park
    set_key CA-0888 VEFF-0888  # Ben Eoin Provincial Park
    set_key CA-0889 VEFF-0889  # Black Duck Cove Provincial Park
    set_key CA-0890 VEFF-0890  # Blue Sea Beach Provincial Park
    set_key CA-0892 VEFF-0892  # Burnt Island Provincial Park
    set_key CA-0894 VEFF-0894  # Caddell Rapids Lookoff Provincial Park
    set_key CA-0895 VEFF-0895  # Camerons Brook Provincial Park
    set_key CA-0896 VEFF-0896  # Card Lake Provincial Park
    set_key CA-0897 VEFF-0897  # Caribou and Munroes Island Provincial Park
    set_key CA-0898 VEFF-0898  # Central Grove Provincial Park
    set_key CA-0899 VEFF-0899  # Chimney Corner Provincial Park Reserve
    set_key CA-0900 VEFF-0900  # Clairmont Provincial Park
    set_key CA-0901 VEFF-0901  # Clam Harbour Beach Provincial Park
    set_key CA-0902 VEFF-0902  # Cleveland Beach Provincial Park
    set_key CA-0903 VEFF-0903  # Cookville Provincial Park
    set_key CA-0904 VEFF-0904  # Cottage Cove Provincial Park
    set_key CA-0905 VEFF-0905  # Dalem Lake Provincial Park
    set_key CA-0906 VEFF-0906  # Dollar Lake Provincial Park
    set_key CA-0908 VEFF-0908  # East River Provincial Park
    set_key CA-0910 VEFF-0910  # Ellenwood Lake Provincial Park
    set_key CA-0911 VEFF-0911  # Falls Lake Provincial Park
    set_key CA-0912 VEFF-0912  # Fancy Lake Provincial Park
    set_key CA-0913 VEFF-0913  # Fox Harbour Provincial Park
    set_key CA-0914 VEFF-0914  # Glenwood Provincial Park
    set_key CA-0915 VEFF-0915  # Green Hill Provincial Park
    set_key CA-0916 VEFF-0916  # Gulf Shore Provincial Park
    set_key CA-0917 VEFF-0917  # Heather Beach Provincial Park
    set_key CA-0919 VEFF-0919  # Joggins Fossil Cliffs Provincial Park
    set_key CA-0920 VEFF-0920  # Lake Charlotte Provincial Park
    set_key CA-0921 VEFF-0921  # Lake George Provincial Park
    set_key CA-0922 VEFF-0922  # Lake Midway Provincial Park
    set_key CA-0923 VEFF-0923  # Laurie Provincial Park
    set_key CA-0924 VEFF-0924  # Lennox Passage Provincial Park
    set_key CA-0925 VEFF-0925  # Lochiel Lake Provincial Park
    set_key CA-0926 VEFF-0926  # Londonderry Provincial Park
    set_key CA-0927 VEFF-0927  # Long Lake Provincial Park
    set_key CA-0928 VEFF-0928  # Lumsden Pond Provincial Park
    set_key CA-0929 VEFF-0929  # MacCormack Beach Provincial Park
    set_key CA-0930 VEFF-0930  # Mickey Hill Provincial Park
    set_key CA-0931 VEFF-0931  # Mira River Provincial Park
    set_key CA-0932 VEFF-0932  # Musquodoboit Valley Provincial Park
    set_key CA-0933 VEFF-0933  # Point Michaud Beach Provincial Park
    set_key CA-0934 VEFF-0934  # Port Hood Station Provincial Park
    set_key CA-0935 VEFF-0935  # Port L'Hebert Provincial Park
    set_key CA-0936 VEFF-0936  # Port Maitland Beach Provincial Park
    set_key CA-0937 VEFF-0937  # Port Shoreham Beach Provincial Park
    set_key CA-0938 VEFF-0938  # Porters Lake Provincial Park
    set_key CA-0939 VEFF-0939  # Powells Point Provincial Park
    set_key CA-0940 VEFF-0940  # Queensland Beach Provincial Park
    set_key CA-0941 VEFF-0941  # Rainbow Haven Beach Provincial Park
    set_key CA-0942 VEFF-0942  # Rissers Beach Provincial Park
    set_key CA-0943 VEFF-0943  # Sable River Provincial Park
    set_key CA-0944 VEFF-0944  # Salsman Provincial Park
    set_key CA-0946 VEFF-0946  # Savary Provincial Park
    set_key CA-0947 VEFF-0947  # Second Peninsula Provincial Park
    set_key CA-0948 VEFF-0948  # Shinimicas Provincial Park
    set_key CA-0949 VEFF-0949  # Smileys Provincial Park
    set_key CA-0950 VEFF-0950  # Smuggler's Cove Provincial Park
    set_key CA-0951 VEFF-0951  # St. Anns Provincial Park
    set_key CA-0952 VEFF-0952  # Tidnish Dock Provincial Park
    set_key CA-0953 VEFF-0953  # Wentworth Provincial Park
    set_key CA-0954 VEFF-0954  # Whycocomagh Provincial Park
    set_key CA-0955 VEFF-0955  # William E. deGarthe Memorial Provincial Park Provincial Park
    set_key CA-0956 VEFF-0956  # Boise de Marly
    set_key CA-0957 VEFF-0957  # Boise de Tequenonday
    set_key CA-0958 VEFF-0958  # Boise des Compagnons-de-Cartier
    set_key CA-0959 VEFF-0959  # La Promenade Samuel-De Champlain
    set_key CA-0960 VEFF-0960  # Morgan Arboretum
    set_key CA-0961 VEFF-0961  # Parc Andre-J.-Cote
    set_key CA-0962 VEFF-0962  # Parc Angrignon
    set_key CA-0963 VEFF-0963  # Parc Carre Royal
    set_key CA-0964 VEFF-0964  # Parc Cartier-Roberval
    set_key CA-0965 VEFF-0965  # Parc Centenaire William Cosgrove
    set_key CA-0966 VEFF-0966  # Parc Centennial Hall
    set_key CA-0967 VEFF-0967  # Parc de l'Ile-Lebel
    set_key CA-0968 VEFF-0968  # Parc de l'Ile Melville
    set_key CA-0969 VEFF-0969  # Parc de l'Ile Saint-Quentin
    set_key CA-0970 VEFF-0970  # Parc de la Plage-Jacques-Cartier
    set_key CA-0971 VEFF-0971  # Parc de la Pointe-aux-Pins
    set_key CA-0972 VEFF-0972  # Parc de la Riviere-des-Mille-Iles
    set_key CA-0973 VEFF-0973  # Parc de la Riviere-du-Moulin
    set_key CA-0974 VEFF-0974  # Parc de la Source
    set_key CA-0975 VEFF-0975  # Parc des Braves
    set_key CA-0976 VEFF-0976  # Parc des Eaux-Vives
    set_key CA-0977 VEFF-0977  # Parc des Montagnards du Mont-Shefford
    set_key CA-0978 VEFF-0978  # Parc des Pionniers
    set_key CA-0979 VEFF-0979  # Parc du Bassin
    set_key CA-0980 VEFF-0980  # Parc du Bois-de-Coulonge
    set_key CA-0981 VEFF-0981  # Parc du Domaine Vert
    set_key CA-0982 VEFF-0982  # Parc du lac Claude
    set_key CA-0983 VEFF-0983  # Parc du Mont-Fortin
    set_key CA-0984 VEFF-0984  # Parc du Mont-Jacob
    set_key CA-0985 VEFF-0985  # Parc ecologique Jean-Paul-Forand du Mont-Shefford
    set_key CA-0986 VEFF-0986  # Parc Frederic-Back
    set_key CA-0987 VEFF-0987  # Parc Hermitage a Pointe-Claire
    set_key CA-0988 VEFF-0988  # Parc Historique de la Croix de Sainte-Anne
    set_key CA-0989 VEFF-0989  # Parc J.-C.-Wilson (secteur chutes Wilson)
    set_key CA-0990 VEFF-0990  # Parc Jarry
    set_key CA-0991 VEFF-0991  # Parc Jean-Baptiste Rolland
    set_key CA-0992 VEFF-0992  # Parc La Fontaine
    set_key CA-0993 VEFF-0993  # Parc Lafontaine
    set_key CA-0994 VEFF-0994  # Parc Maisonneuve
    set_key CA-0995 VEFF-0995  # Parc-nature de Ile-de-la-Visitation
    set_key CA-0996 VEFF-0996  # Parc-nature de l'Anse-a-l'Orme
    set_key CA-0997 VEFF-0997  # Parc-nature de la Pointe-aux-Prairies
    set_key CA-0998 VEFF-0998  # Parc-nature du Bois-de-Saraguay
    set_key CA-0999 VEFF-0999  # Parc-nature du Cap-Saint-Jacques
    set_key CA-1000 VEFF-1000  # Parc-nature du Ruisseau-De Montigny
    set_key CA-1001 VEFF-1001  # Parc naturel Terra-Cotta
    set_key CA-1002 VEFF-1002  # Parc Regard-sur-le-Fleuve
    set_key CA-1003 VEFF-1003  # Parc regional Bois de Belle-Riviere
    set_key CA-1004 VEFF-1004  # Parc regional de Beauharnois-Salaberry
    set_key CA-1005 VEFF-1005  # Parc regional de la Foret Ouareau
    set_key CA-1006 VEFF-1006  # Parc regional de la Montagne du Diable
    set_key CA-1007 VEFF-1007  # Parc regional de la Riviere-du-Nord (Chutes Wilson)
    set_key CA-1008 VEFF-1008  # Parc regional des Appalaches
    set_key CA-1009 VEFF-1009  # Parc regional des Chutes-Monte-a-Peine-et-des-Dalles
    set_key CA-1010 VEFF-1010  # Parc regional des Greves
    set_key CA-1011 VEFF-1011  # Parc regional du Massif du Sud
    set_key CA-1012 VEFF-1012  # Parc regional du Mont-Ham
    set_key CA-1013 VEFF-1013  # Parc regional du Poisson Blanc
    set_key CA-1014 NIL-0000  # Parc regional Val-David-Val-Morin; WWFF candidates: VEFF-1014, VEFF-4899
    set_key CA-1015 VEFF-1015  # Parc riverain de la Sainte-Anne
    set_key CA-1016 VEFF-1016  # Parc Rosaire-Gauthier
    set_key CA-1017 VEFF-1017  # Parc Sir William Price (aka Parc Ball)
    set_key CA-1018 VEFF-1018  # Parc Stewart (Stewart Hall)
    set_key CA-1019 VEFF-1019  # Plaines d'Abraham
    set_key CA-1020 VEFF-1020  # Recre-O-Parc de Sainte-Catherine
    set_key CA-1021 VEFF-1021  # Reserve de parc national Assinica
    set_key CA-1022 VEFF-1022  # Reserve ecologique de Samuel-Brisson
    set_key CA-1023 VEFF-1023  # Reserve faunique de Matane
    set_key CA-1024 VEFF-1024  # Reserve faunique de Papineau-Labelle
    set_key CA-1025 VEFF-1025  # Reserve faunique des Chic-Chocs
    set_key CA-1026 VEFF-1026  # Reserve faunique des Laurentides
    set_key CA-1027 VEFF-1027  # Reserve faunique La Verendrye
    set_key CA-1028 VEFF-1028  # Reserve faunique Mastigouche
    set_key CA-1029 VEFF-1029  # Reserve faunique Rouge-Matawin
    set_key CA-1030 VEFF-1030  # Reserve naturelle Alfred-Kelly
    set_key CA-1031 VEFF-1031  # Reserve naturelle de Pointe-Yamachiche
    set_key CA-1032 VEFF-1032  # Reserve naturelle des Rapides-de-Lachine
    set_key CA-1033 VEFF-1033  # Reserve naturelle du Bois-de-Brossard
    set_key CA-1034 VEFF-1034  # Reserve naturelle du Boise-Du-Tremblay
    set_key CA-1035 VEFF-1035  # Reserve naturelle du Boise-Fisher-Woods
    set_key CA-1036 VEFF-1036  # Vallee Bras-du-Nord
    set_key CA-1037 VEFF-1037  # Zone Portuaire de Chicoutimi
    set_key CA-1038 VEFF-1038  # Amable du Fond River Provincial Park
    set_key CA-1039 VEFF-1039  # Aubinadong River Provincial Park
    set_key CA-1040 VEFF-1040  # Burnt Lands Provincial Park
    set_key CA-1041 VEFF-1041  # Gem Lake Maple Bedrock Provincial Park
    set_key CA-1042 VEFF-1042  # Goose Island Provincial Park
    set_key CA-1043 VEFF-1043  # Mount Nemo Conservation Area
    set_key CA-1044 VEFF-1044  # Nimoosh Provincial Park
    set_key CA-1045 VEFF-1045  # Puzzle Lake Provincial Park
    set_key CA-1046 VEFF-1046  # Rattlesnake Point Conservation Area
    set_key CA-1047 VEFF-1047  # Rushbrook Provincial Park
    set_key CA-1048 VEFF-1048  # Assiniboine Park
    set_key CA-1049 VEFF-1049  # Bell Lake Provincial Park
    set_key CA-1050 VEFF-1050  # Grassy Narrows Park
    set_key CA-1051 VEFF-1051  # Hnausa Beach Provincial Park
    set_key CA-1052 VEFF-1052  # Hyland Provincial Park
    set_key CA-1053 VEFF-1053  # International Peace Garden
    set_key CA-1054 VEFF-1054  # Lake St. George Provincial Park
    set_key CA-1055 VEFF-1055  # Lower Fort Garry National Historic Site
    set_key CA-1056 VEFF-1056  # Lundar Beach Provincial Park
    set_key CA-1057 VEFF-1057  # Margaret Bruce Provincial Park
    set_key CA-1058 VEFF-1058  # Mennonite Heritage Village Provincial Park
    set_key CA-1059 VEFF-1059  # Neso Lake Provincial Park
    set_key CA-1060 VEFF-1060  # Netley Creek Provincial Park
    set_key CA-1061 VEFF-1061  # Oak Lake Provincial Park
    set_key CA-1062 VEFF-1062  # Overflowing River Provincial Park
    set_key CA-1063 VEFF-1063  # Pembina Valley Provincial Park
    set_key CA-1064 VEFF-1064  # Pinawa Dam Provincial Heritage Park
    set_key CA-1065 VEFF-1065  # Poplar Bay Provincial Park
    set_key CA-1066 VEFF-1066  # Portage Spillway Provincial Park
    set_key CA-1067 VEFF-1067  # Prince of Wales Fort National Historic Site
    set_key CA-1068 VEFF-1068  # Rainbow Beach Provincial Park
    set_key CA-1069 VEFF-1069  # Riel House Provincial Park
    set_key CA-1070 VEFF-1070  # Rocky Lake Provincial Park
    set_key CA-1071 VEFF-1071  # Sand Lakes Provincial Park
    set_key CA-1072 VEFF-1072  # Sasagiu Rapids Provincial Park
    set_key CA-1073 VEFF-1073  # Seton Provincial Park
    set_key CA-1074 VEFF-1074  # Springwater Provincial Park
    set_key CA-1075 VEFF-1075  # St. Ambroise Beach Provincial Park
    set_key CA-1076 VEFF-1076  # St. Malo Provincial Park
    set_key CA-1077 VEFF-1077  # Sturgeon Bay Provincial Park Reserve
    set_key CA-1078 VEFF-1078  # Swan River Provincial Park
    set_key CA-1079 VEFF-1079  # The Forks National Historic Site
    set_key CA-1080 VEFF-1080  # Twin Lakes Provincial Park
    set_key CA-1081 VEFF-1081  # Upper Fort Garry Provincial Park
    set_key CA-1082 VEFF-1082  # Wallace Lake Provincial Park
    set_key CA-1083 VEFF-1083  # Watchorn Provincial Park
    set_key CA-1084 VEFF-1084  # Wekusko Falls Provincial Park
    set_key CA-1085 VEFF-1085  # Whitefish Lake Provincial Park
    set_key CA-1086 VEFF-1086  # Whitemouth Falls Provincial Park
    set_key CA-1087 VEFF-1087  # Whiteshell Provincial Park
    set_key CA-1088 VEFF-1088  # Winnipeg Beach Provincial Park
    set_key CA-1089 VEFF-1089  # Woodridge Provincial Park
    set_key CA-1090 VEFF-1090  # Yellow Quill Provincial Park
    set_key CA-1091 VEFF-1091  # York Factory Provincial Park
    set_key CA-1092 VEFF-1092  # Zed Lake Provincial Park
    set_key CA-1093 VEFF-1093  # Antelope Lake Regional Park
    set_key CA-1094 VEFF-1094  # Assiniboia Regional Park
    set_key CA-1095 VEFF-1095  # Atton's Lake Regional Park
    set_key CA-1096 VEFF-1096  # Bengough &amp;amp
    set_key CA-1097 VEFF-1097  # Big River Regional Park
    set_key CA-1098 VEFF-1098  # Brightsand Lake Regional Park
    set_key CA-1099 VEFF-1099  # Cabri Regional Park
    set_key CA-1100 VEFF-1100  # Canwood Regional Park
    set_key CA-1101 VEFF-1101  # Carlton Trail Regional Park
    set_key CA-1102 VEFF-1102  # Ceylon Regional Park
    set_key CA-1103 VEFF-1103  # Clearwater Regional Park
    set_key CA-1104 VEFF-1104  # Craik &amp; District Regional Park
    set_key CA-1105 VEFF-1105  # Dunnet Regional Park
    set_key CA-1106 VEFF-1106  # Eagle Creek Regional Park
    set_key CA-1107 VEFF-1107  # Emerald Lake Regional Park
    set_key CA-1108 VEFF-1108  # Eston Riverside Regional Park
    set_key CA-1109 VEFF-1109  # Glenburn Regional Park
    set_key CA-1110 VEFF-1110  # Hudson Bay Regional Park
    set_key CA-1111 VEFF-1111  # Ituna &amp;amp
    set_key CA-1112 VEFF-1112  # Jean Louis Legare Regional Park
    set_key CA-1113 VEFF-1113  # Kemoca Regional Park
    set_key CA-1114 VEFF-1114  # Kindersley Regional Park
    set_key CA-1115 VEFF-1115  # Kipabiskau Regional Park
    set_key CA-1116 VEFF-1116  # Lac Pelletier Regional Park
    set_key CA-1117 VEFF-1117  # Lake Charron Regional Park
    set_key CA-1118 VEFF-1118  # Last Mountain Regional Park
    set_key CA-1119 VEFF-1119  # Leroy Leisureland Regional Park
    set_key CA-1120 VEFF-1120  # Leslie Beach Regional Park
    set_key CA-1121 VEFF-1121  # Little Loon Regional Park
    set_key CA-1122 VEFF-1122  # Lucien Lake Regional Park
    set_key CA-1123 VEFF-1123  # Macklin Lake Regional Park
    set_key CA-1124 VEFF-1124  # Mainprize Regional Park
    set_key CA-1125 VEFF-1125  # Manitou &amp;amp
    set_key CA-1126 VEFF-1126  # Martins Lake Regional Park
    set_key CA-1127 VEFF-1127  # McLaren Lake Regional Park
    set_key CA-1128 VEFF-1128  # McNab Regional Park
    set_key CA-1129 VEFF-1129  # Meeting Lake Regional Park
    set_key CA-1130 VEFF-1130  # Melville Regional Park
    set_key CA-1131 VEFF-1131  # Memorial Lake Regional Park
    set_key CA-1132 VEFF-1132  # Meota Regional Park
    set_key CA-1133 VEFF-1133  # Moose Creek Regional Park
    set_key CA-1134 VEFF-1134  # Moosomin &amp; District Regional Park
    set_key CA-1135 VEFF-1135  # Morin Lake Regional Park
    set_key CA-1136 VEFF-1136  # Nickle Lake Regional Park
    set_key CA-1137 VEFF-1137  # Nipawin &amp;amp
    set_key CA-1138 VEFF-1138  # Notukeu Regional Park
    set_key CA-1139 VEFF-1139  # Ogema Regional Park
    set_key CA-1140 VEFF-1140  # Oungre Memorial Regional Park
    set_key CA-1141 VEFF-1141  # Palliser Regional Park
    set_key CA-1142 VEFF-1142  # Pasquia Regional Park
    set_key CA-1143 VEFF-1143  # Pine Cree Regional Park
    set_key CA-1144 VEFF-1144  # Prairie Lake Regional Park
    set_key CA-1145 VEFF-1145  # Radville-Laurier Regional Park
    set_key CA-1146 VEFF-1146  # Redberry Lake Regional Park
    set_key CA-1147 VEFF-1147  # Saltcoats &amp;amp
    set_key CA-1148 VEFF-1148  # Sandy Beach Regional Park
    set_key CA-1149 VEFF-1149  # Shamrock Regional Park
    set_key CA-1150 VEFF-1150  # Silver Lake Regional Park
    set_key CA-1151 VEFF-1151  # St. Brieux Regional Park
    set_key CA-1152 VEFF-1152  # Struthers Lake Regional Park
    set_key CA-1153 VEFF-1153  # Sturgeon Lake Regional Park
    set_key CA-1154 VEFF-1154  # Sturgis &amp; District Regional Park - Lady Lake
    set_key CA-1155 VEFF-1155  # Suffern Lake Regional Park
    set_key CA-1156 VEFF-1156  # Thomas Lake Regional Park
    set_key CA-1157 VEFF-1157  # Valley - Rosthern Regional Park
    set_key CA-1158 VEFF-1158  # Wakaw Lake Regional Park
    set_key CA-1159 VEFF-1159  # Wapiti Valley Regional Park
    set_key CA-1160 VEFF-1160  # Welwyn Centennial Regional Park
    set_key CA-1161 VEFF-1161  # Whitesand Regional Park
    set_key CA-1162 VEFF-1162  # York Lake Regional Park
    set_key CA-1163 VEFF-1163  # Aspen Beach Provincial Park
    set_key CA-1164 VEFF-1164  # Beaver Lake Provincial Recreation Area
    set_key CA-1165 VEFF-1165  # Beaverdam Provincial Recreation Area
    set_key CA-1166 VEFF-1166  # Calhoun Bay Provincial Recreation Area
    set_key CA-1167 VEFF-1167  # Canmore Nordic Centre Provincial Park
    set_key CA-1168 VEFF-1168  # Chain Lakes Provincial Park
    set_key CA-1169 VEFF-1169  # Chambers Creek Provincial Recreation Area
    set_key CA-1170 VEFF-1170  # Chinook Provincial Recreation Area
    set_key CA-1171 VEFF-1171  # Cold Lake Provincial Park
    set_key CA-1172 VEFF-1172  # Crescent Falls Provincial Recreation Area
    set_key CA-1173 VEFF-1173  # Cross Lake Provincial Park
    set_key CA-1174 VEFF-1174  # Crow Lake Provincial Park
    set_key CA-1175 VEFF-1175  # Dry Haven Provincial Recreation Area
    set_key CA-1176 VEFF-1176  # Dutch Creek Provincial Recreation Area
    set_key CA-1177 VEFF-1177  # Elbow Falls Provincial Recreation Area
    set_key CA-1178 VEFF-1178  # Engstrom Lake Provincial Recreation Area
    set_key CA-1179 VEFF-1179  # Garner Lake Provincial Park
    set_key CA-1180 VEFF-1180  # Jarvis Bay Provincial Park
    set_key CA-1181 VEFF-1181  # Kinbrook Island Provincial Park
    set_key CA-1182 VEFF-1182  # Lesser Slave Lake Provincial Park
    set_key CA-1183 VEFF-1183  # Little Bow Provincial Park
    set_key CA-1184 VEFF-1184  # Little Fish Lake Provincial Park
    set_key CA-1185 VEFF-1185  # Lois Hole Centennial Provincial Park
    set_key CA-1186 VEFF-1186  # O'Brien Provincial Park
    set_key CA-1187 VEFF-1187  # Park Lake Provincial Park
    set_key CA-1188 VEFF-1188  # Pembina River Provincial Park
    set_key CA-1189 VEFF-1189  # Pigeon Lake Provincial Park
    set_key CA-1190 VEFF-1190  # Queen Elizabeth Provincial Park
    set_key CA-1191 VEFF-1191  # Red Lodge Provincial Park
    set_key CA-1192 VEFF-1192  # Rochon Sands Provincial Park
    set_key CA-1193 VEFF-1193  # Strathcona Science Provincial Park
    set_key CA-1194 VEFF-1194  # Sylvan Lake Provincial Park
    set_key CA-1195 VEFF-1195  # Thunder Lake Provincial Park
    set_key CA-1196 VEFF-1196  # Tillebrook Provincial Park
    set_key CA-1197 VEFF-1197  # Victoria Settlement Provincial Historic Site
    set_key CA-1198 VEFF-1198  # Wabamun Lake Provincial Park
    set_key CA-1199 VEFF-1199  # Williamson Provincial Park
    set_key CA-1200 VEFF-1200  # Willow Creek Provincial Park
    set_key CA-1201 VEFF-1201  # Woolford Provincial Park
    set_key CA-1202 VEFF-1202  # Wyndham-Carseland Provincial Park
    set_key CA-1203 VEFF-1203  # Anarchist Protected Area
    set_key CA-1204 VEFF-1204  # Apodaca Provincial Park
    set_key CA-1205 VEFF-1205  # Arbutus Grove Provincial Park
    set_key CA-1206 VEFF-1206  # Beatton Provincial Park
    set_key CA-1207 VEFF-1207  # Beaumont Provincial Park
    set_key CA-1208 VEFF-1208  # Beaver Creek Provincial Park
    set_key CA-1209 VEFF-1209  # Bedard Aspen Provincial Park
    set_key CA-1210 VEFF-1210  # Bellhouse Provincial Park
    set_key CA-1211 VEFF-1211  # Big Bar Lake Provincial Park
    set_key CA-1212 VEFF-1212  # Bijoux Falls Provincial Park
    set_key CA-1213 VEFF-1213  # Bishop River Provincial Park
    set_key CA-1214 VEFF-1214  # Blackcomb Glacier Provincial Park
    set_key CA-1215 VEFF-1215  # Blanket Creek Provincial Park
    set_key CA-1216 VEFF-1216  # Bobtail Mountain Provincial Park
    set_key CA-1217 VEFF-1217  # Bodega Ridge Provincial Park
    set_key CA-1218 VEFF-1218  # Boundary Creek Provincial Park
    set_key CA-1219 VEFF-1219  # Brackendale Eagles Provincial Park
    set_key CA-1220 VEFF-1256  # Arthur Kyle Nature Preserve
    set_key CA-1221 VEFF-1257  # Bass Brook Nature Reserve
    set_key CA-1222 VEFF-1258  # Berry Brook Nature Reserve
    set_key CA-1223 VEFF-1259  # Blueberry Hill Nature Preserve
    set_key CA-1224 VEFF-1260  # Boar's Head Nature Preserve
    set_key CA-1225 VEFF-1261  # Caledonia Gorge Protected Area
    set_key CA-1226 VEFF-1262  # Cape Enrage Marsh Nature Preserve
    set_key CA-1227 VEFF-1263  # Caughey-Taylor Nature Preserve
    set_key CA-1228 VEFF-1264  # Clarke Brook Nature Reserve
    set_key CA-1229 VEFF-1265  # Connors Brook Nature Reserve
    set_key CA-1230 VEFF-1266  # Cranberry Lake Nature Reserve
    set_key CA-1231 VEFF-1267  # Daly Point Nature Reserve
    set_key CA-1232 VEFF-1268  # Dipper Harbour Back Cove Nature Reserve
    set_key CA-1233 VEFF-1269  # Dungarvon Nature Reserve
    set_key CA-1234 VEFF-1270  # Dungarvon Whooper Spring Woodlot Nature Reserve
    set_key CA-1235 VEFF-1272  # Glazier Lake Nature Reserve
    set_key CA-1236 VEFF-1273  # Goose Lake Nature Reserve
    set_key CA-1237 VEFF-1274  # Goulette Brook Nature Reserve
    set_key CA-1238 VEFF-1275  # Grand Lake Nature Reserve
    set_key CA-1239 VEFF-1276  # Grindstone Island Conservation Easement Nature Reserve
    set_key CA-1240 VEFF-1277  # Hyla Park Nature Preserve Nature Reserve
    set_key CA-1241 VEFF-1278  # Irving Nature Park Nature Reserve
    set_key CA-1242 VEFF-1279  # James C. Yerxa Nature Preserve
    set_key CA-1243 VEFF-1280  # Loch Alva Nature Reserve
    set_key CA-1245 VEFF-1282  # Minister's Face Nature Preserve
    set_key CA-1246 VEFF-1283  # Oakland Mountain Nature Reserve
    set_key CA-1247 VEFF-1284  # Otter Brook Nature Reserve
    set_key CA-1248 VEFF-1285  # Pagan Point Nature Preserve
    set_key CA-1249 VEFF-1286  # Pickerel Pond Nature Preserve
    set_key CA-1250 VEFF-1287  # Pokeshaw Nature Reserve
    set_key CA-1251 VEFF-1288  # Rockwood Park Nature Reserve
    set_key CA-1252 VEFF-1289  # Saints Rest Marsh - F. Gordon Carvell Nature Preserve
    set_key CA-1253 VEFF-1290  # Sea Dog Cove Nature Preserve
    set_key CA-1254 VEFF-1291  # Seven Days Work Cliff Nature Preserve
    set_key CA-1255 VEFF-1292  # Sugar Island Nature Preserve
    set_key CA-1256 VEFF-1293  # Thomas B. Munro Memorial Shoreline Nature Reserve
    set_key CA-1257 VEFF-1294  # Upsalquitch Forks Nature Reserve
    set_key CA-1258 VEFF-1295  # Val Comeau Provincial Park
    set_key CA-1259 VEFF-1296  # Williamstown Lake Nature Reserve
    set_key CA-1260 VEFF-1297  # Avalon Wilderness Reserve
    set_key CA-1261 VEFF-1298  # Baccalieu Island Ecological Reserve
    set_key CA-1262 VEFF-1300  # Burnt Cape Ecological Reserve
    set_key CA-1263 VEFF-1301  # Cape St. Mary's Ecological Reserve
    set_key CA-1264 VEFF-1303  # Deadman's Bay Provincial Park
    set_key CA-1265 VEFF-1304  # Fortune Head Park Reserve
    set_key CA-1266 VEFF-1305  # Gannet Islands Park Reserve
    set_key CA-1268 VEFF-1308  # Hawke Hills Park Reserve
    set_key CA-1269 VEFF-1309  # King George IV Ecological Reserve
    set_key CA-1270 VEFF-1310  # Main River Waterway Provincial Park
    set_key CA-1272 VEFF-1313  # Redfir Lake - Kapitagas Channel Ecological Reserve
    set_key CA-1273 VEFF-1316  # Table Point Ecological Reserve
    set_key CA-1274 VEFF-1319  # Watt's Point Park Reserve
    set_key CA-1275 VEFF-1320  # Witless Bay Islands Park Reserve
    set_key CA-1276 VEFF-1326  # Blooming Point Woodlands Natural Area
    set_key CA-1277 VEFF-1327  # Buffalo Land Provincial Park
    set_key CA-1278 VEFF-1328  # Forest Hill Wildlife Management Area
    set_key CA-1279 VEFF-3426  # A.W. Campbell Conservation Area
    set_key CA-1280 VEFF-1922  # Abitibi Lake Narrows Wilderness Area
    set_key CA-1281 VEFF-1923  # Adair Lake Conservation Reserve
    set_key CA-1282 VEFF-4352  # Agate Island Wilderness Area
    set_key CA-1283 VEFF-4057  # Ahmic Forest and Rock Barrens
    set_key CA-1284 VEFF-4058  # Airport Road Conservation Reserve
    set_key CA-1286 VEFF-4060  # Akonesi Chain Of Lakes Complex
    set_key CA-1287 VEFF-1331  # Alexander Lake Forest Provincial Park
    set_key CA-1288 VEFF-4059  # Alm Lake Forest Conservation Reserve
    set_key CA-1289 VEFF-4061  # Archambeau Lake Forest
    set_key CA-1290 VEFF-4358  # Attlee Central Forest Conservation Reserve
    set_key CA-1291 VEFF-4359  # Attlee Conservation Reserve
    set_key CA-1292 VEFF-4360  # Attwood River Conservation Reserve
    set_key CA-1293 VEFF-4361  # Aulneau Interior Conservation Reserve
    set_key CA-1294 VEFF-2547  # Aviation Museum Woods Conservation Reserve
    set_key CA-1295 VEFF-4062  # Axe Lake Wetland
    set_key CA-1296 VEFF-1924  # Ballantyne Lake Drumlins Conservation Reserve Conservation Reserve
    set_key CA-1297 VEFF-2548  # Ball's Falls Conservation Area
    set_key CA-1298 VEFF-4063  # Bannister Lake Complex
    set_key CA-1299 VEFF-4064  # Bannockburn Conservation Reserve
    set_key CA-1302 VEFF-1336  # Barron River Provincial Park
    set_key CA-1303 VEFF-1925  # Basswood Lake Conservation Reserve
    set_key CA-1306 VEFF-1337  # Batchawana River Provincial Park
    set_key CA-1307 VEFF-2963  # Beamer Memorial Conservation Reserve
    set_key CA-1310 VEFF-1341  # Beekahncheekahmeeng Deebahncheekayweehn Eenahohnahnuhn Provincial Park
    set_key CA-1312 VEFF-2551  # Beverly Swamp Conservation Reserve
    set_key CA-1313 VEFF-1929  # Bickford Oak Woods Conservation Reserve
    set_key CA-1317 VEFF-1345  # Bissett Creek Provincial Park
    set_key CA-1319 VEFF-2553  # Black Rapids Creek Conservation Reserve
    set_key CA-1323 VEFF-2555  # Borer's Falls Conservation Reserve
    set_key CA-1346 VEFF-2558  # Cedar Valley Conservation Area
    set_key CA-1349 VEFF-2561  # Champlain Bridge and Lemieux Islands Conservation Reserve
    set_key CA-1350 VEFF-2562  # Chapel Hill's North Forest Conservation Reserve
    set_key CA-1351 VEFF-4075  # Cherriman Township Conservation Reserve
    set_key CA-1353 VEFF-2564  # Clear Lake Conservation Reserve
    set_key CA-1356 VEFF-1932  # Cognashene Point Conservation Reserve
    set_key CA-1358 VEFF-2566  # Conroys Marsh Conservation Reserve
    set_key CA-1359 VEFF-1934  # Constant Creek Swamp And Fen Conservation Area
    set_key CA-1368 VEFF-3617  # North Maple Regional Park
    set_key CA-1375 VEFF-1351  # DuPont Provincial Park
    set_key CA-1385 VEFF-1349  # Chapman Mills Conservation Area
    set_key CA-1386 VEFF-3497  # Eau Claire Gorge Conservation Reserve
    set_key CA-1390 VEFF-2990  # Purple Woods Conservation Area Conservation Area
    set_key CA-1392 VEFF-2569  # Elora Gorge Conservation Reserve
    set_key CA-1397 VEFF-1941  # Felker's Falls Conservation Area
    set_key CA-1418 VEFF-2574  # Goulais River Beach Ridges Conservation Reserve
    set_key CA-1419 VEFF-1365  # Goulais River Provincial Park
    set_key CA-1420 VEFF-1366  # Grant's Creek Provincial Park
    set_key CA-1421 VEFF-1367  # Grassy River Halliday Lake Forests &amp; Lowlands Conservation Reserve
    set_key CA-1422 VEFF-1368  # Grassy River-Mond Lake Lowlands And Ferris Lake Uplands Provincial Park Provincial Park
    set_key CA-1425 VEFF-4087  # Green's Creek
    set_key CA-1427 VEFF-3525  # Greenwood Conservation Reserve
    set_key CA-1429 VEFF-1369  # Groundhog River Waterway Provincial Park
    set_key CA-1430 VEFF-1370  # Gull River Provincial Park
    set_key CA-1436 VEFF-4932  # Hawkins Property Conservation Reserve
    set_key CA-1437 VEFF-2975  # Heber Down Conservation Reserve
    set_key CA-1440 VEFF-2577  # Hilton Falls Conservation Area
    set_key CA-1447 VEFF-1946  # Iroquoia Heights Conservation Reserve
    set_key CA-1458 VEFF-1375  # Kahnahmaykoosayseekahk Provincial Park
    set_key CA-1490 VEFF-3582  # Louth Falls Conservation Reserve
    set_key CA-1494 VEFF-2980  # Lynde Shores Conservation Reserve
    set_key CA-1497 VEFF-1378  # MacMurchy Township End Moraine Provincial Park
    set_key CA-1505 VEFF-1379  # Mattagami River Beach and Aeolian Deposit Provincial Park
    set_key CA-1506 VEFF-4100  # McCarthy Woods Conservation Reserve
    set_key CA-1513 VEFF-1950  # Melgund Lake Conservation Reserve
    set_key CA-1515 VEFF-4101  # Mer Bleue Bog
    set_key CA-1516 VEFF-2583  # Mer Bleue Conservation Reserve
    set_key CA-1525 VEFF-4102  # Morningside Park Conservation Reserve
    set_key CA-1528 VEFF-3614  # Mountsberg Conservation Reserve
    set_key CA-1531 VEFF-3615  # Mud Lake Conservation Reserve
    set_key CA-1532 VEFF-4947  # Mud Lake / Creek Conservation Reserve
    set_key CA-1541 VEFF-1935  # Crawford Lake Conservation Reserve
    set_key CA-1556 VEFF-1386  # Obonga-Ottertooth Provincial Park
    set_key CA-1558 VEFF-1387  # Ogoki River Provincial Park
    set_key CA-1568 VEFF-1388  # Pahngwahshahshk Ohweemushkeeg Provincial Park
    set_key CA-1571 VEFF-1389  # Pan Lake Fen Provincial Park
    set_key CA-1575 VEFF-1390  # Petawawa Terrace Provincial Park
    set_key CA-1576 VEFF-2590  # Petticoat Creek Conservation Reserve
    set_key CA-1579 VEFF-4105  # Pine Grove Forest Conservation Reserve
    set_key CA-1581 VEFF-4106  # Pinhey Forest Conservation Reserve
    set_key CA-1585 VEFF-1393  # Pokei Lake / White River Wetlands Provincial Park
    set_key CA-1587 VEFF-1958  # Tiffany Falls Conservation Area
    set_key CA-1595 VEFF-2961  # Altona Forest Conservation Area
    set_key CA-1596 VEFF-1373  # Rideau River, Hog's Back Conservation Reserve
    set_key CA-1597 VEFF-2991  # Rockcliffe Park Conservation Reserve
    set_key CA-1598 VEFF-2992  # Rockway Falls Conservation Reserve
    set_key CA-1602 VEFF-1395  # Sahkeesuhkuh Weesuhkaheegahn Provincial Park
    set_key CA-1621 VEFF-4108  # Shirleys Bay Conservation Reserve
    set_key CA-1626 VEFF-2993  # Silver Creek Peatland Conservation Reserve
    set_key CA-1631 VEFF-4953  # Snake River Marsh Conservation Reserve
    set_key CA-1638 VEFF-1404  # W.A. Taylor Conservation Area
    set_key CA-1639 VEFF-3671  # Spencer Gorge/Webster Falls Conservation Reserve
    set_key CA-1642 VEFF-1399  # St. Raphael Lake Provincial Park
    set_key CA-1645 VEFF-4111  # Stony Swamp Conservation Reserve
    set_key CA-1646 VEFF-3682  # Stoney Island Conservation Reserve
    set_key CA-1651 VEFF-4432  # Summit Muskeg Preserve
    set_key CA-1657 VEFF-1364  # Glengarry Landing National Historic Site
    set_key CA-1658 VEFF-1400  # Sunnidale Park Recreation Park
    set_key CA-1659 VEFF-3488  # Dumfries Conservation Area
    set_key CA-1660 VEFF-1352  # Edenvale Conservation Area
    set_key CA-1661 VEFF-1360  # Fort Willow Conservation Area
    set_key CA-1673 VEFF-3576  # Little Cataraqui Creek
    set_key CA-1678 VEFF-1384  # New Lowell Conservation Area
    set_key CA-1680 VEFF-3701  # Vimy Lake Uplands
    set_key CA-1685 VEFF-1961  # Wainfleet Bog Conservation Reserve
    set_key CA-1689 VEFF-3707  # Warkworth Conservation Area
    set_key CA-1690 VEFF-2600  # Warsaw Caves Conservation Area
    set_key CA-1691 VEFF-3708  # Warwick Conservation Area
    set_key CA-1692 VEFF-3710  # Waterford North Conservation Area
    set_key CA-1695 VEFF-3564  # Lake Wawanosh Conservation Area
    set_key CA-1697 VEFF-3711  # Wawanosh Valley Conservation Area
    set_key CA-1698 VEFF-3712  # Wawanosh Wetlands Conservation Area
    set_key CA-1699 VEFF-1405  # Weeskayjahk Ohtahzhoganeeng Provincial Park
    set_key CA-1701 VEFF-4958  # Westmeath Bog Conservation Reserve
    set_key CA-1703 VEFF-4960  # White Lake Conservation Reserve
    set_key CA-1706 VEFF-2601  # Whitefish Lakes Conservation Reserve
    set_key CA-1710 VEFF-1406  # Whitesand Provincial Park
    set_key CA-1711 VEFF-1407  # Widdifield Forest Provincial Park
    set_key CA-1713 VEFF-1408  # Wildgoose Outwash Deposit Provincial Park
    set_key CA-1716 VEFF-1832  # Abraham Lake Nature Reserve
    set_key CA-1717 VEFF-1431  # Alder Grounds Wilderness Area
    set_key CA-1718 VEFF-1835  # Amherst Point Bird Sanctuary
    set_key CA-1719 VEFF-1836  # Angevine Lake Nature Reserve
    set_key CA-1720 VEFF-1837  # Aylesford Mountain Nature Reserve
    set_key CA-1721 VEFF-3833  # Baddeck River Wilderness Area
    set_key CA-1722 VEFF-1838  # Baleine Nature Reserve
    set_key CA-1723 VEFF-3834  # Barneys River Nature Reserve
    set_key CA-1724 VEFF-1433  # Barrachois Provincial Park
    set_key CA-1726 VEFF-1839  # Bennery Lake Nature Reserve
    set_key CA-1727 VEFF-1840  # Big Glace Bay Lake Bird Sanctuary
    set_key CA-1728 VEFF-3837  # Black River Bog Nature Reserve
    set_key CA-1729 VEFF-1841  # Blandford Nature Reserve
    set_key CA-1730 VEFF-1435  # Blue Mountain - Birch Cove Lakes Wilderness Area
    set_key CA-1731 VEFF-1436  # Boggy Lake Wilderness Area
    set_key CA-1732 VEFF-1437  # Bonnet Lake Barrens Wilderness Area
    set_key CA-1733 VEFF-1842  # Bornish Hill Nature Reserve
    set_key CA-1734 VEFF-1438  # Bowers Meadows Wilderness Area
    set_key CA-1735 VEFF-1843  # Cains Mountain Wilderness Area
    set_key CA-1736 VEFF-4791  # Calvary River Wilderness Area
    set_key CA-1737 VEFF-1441  # Canso Coastal Barrens Wilderness Area
    set_key CA-1738 VEFF-1845  # Caribou Rivers Nature Reserve
    set_key CA-1739 VEFF-1846  # Cedar Lake Nature Reserve
    set_key CA-1740 VEFF-2335  # Chignecto Isthmus Wilderness Area
    set_key CA-1741 VEFF-3840  # Chimney Corner Nature Reserve
    set_key CA-1742 VEFF-1440  # Clattenburgh Brook Wilderness Area
    set_key CA-1743 VEFF-1442  # Cloud Lake Wilderness Area
    set_key CA-1744 VEFF-2338  # Cowan Brook Nature Reserve
    set_key CA-1745 VEFF-1848  # Dalhousie Mountain Nature Reserve
    set_key CA-1746 VEFF-1444  # Denis Lakes Wilderness Area
    set_key CA-1747 VEFF-3842  # Devils Jaw Wilderness Area
    set_key CA-1748 VEFF-3843  # Diligent River Nature Reserve
    set_key CA-1749 VEFF-1849  # Dochertys Brook Nature Reserve
    set_key CA-1750 VEFF-3845  # Drug Brook Nature Reserve
    set_key CA-1751 VEFF-1850  # Duncans Cove Nature Reserve
    set_key CA-1752 VEFF-3846  # Dunraven Bog Nature Reserve
    set_key CA-1753 VEFF-3847  # Eagles Nest Nature Reserve
    set_key CA-1755 VEFF-3848  # Economy Point Nature Reserve
    set_key CA-1756 VEFF-1851  # Economy River Wilderness Area
    set_key CA-1757 VEFF-3849  # Eigg Mountain - James River Wilderness Area
    set_key CA-1758 VEFF-3850  # Eighteen Mile Brook Nature Reserve
    set_key CA-1759 VEFF-1445  # Elderbank Provincial Park
    set_key CA-1760 VEFF-2340  # Five Bridge Lakes Wilderness Area
    set_key CA-1761 VEFF-1852  # Fossil Coast Nature Reserve
    set_key CA-1762 VEFF-3851  # Fourchu Coast Wilderness Area
    set_key CA-1763 VEFF-1452  # French River Wilderness Area
    set_key CA-1764 VEFF-1853  # Gabarus Wilderness Area
    set_key CA-1765 VEFF-3852  # Ghost Antler Nature Reserve
    set_key CA-1766 VEFF-3838  # Blomidon Look-off Provincial Park
    set_key CA-1768 VEFF-1854  # Gully Lake Wilderness Area
    set_key CA-1769 VEFF-1456  # Haley Lake Migratory Bird Sanctuary
    set_key CA-1770 VEFF-1857  # Harrison Woods Nature Reserve
    set_key CA-1771 VEFF-1458  # Hubbards Provincial Park (Hubbards Community Waterfront and Park)
    set_key CA-1773 VEFF-3855  # Indian Man Lake Nature Reserve
    set_key CA-1775 VEFF-1858  # Irish Cove Nature Reserve
    set_key CA-1776 VEFF-3856  # Janvrin Island Nature Reserve
    set_key CA-1777 VEFF-1860  # Jim Campbells Barren Wilderness Area
    set_key CA-1778 VEFF-3858  # Kelley River Wilderness Area
    set_key CA-1779 VEFF-3859  # Kennetcook River Nature Reserve
    set_key CA-1780 VEFF-1861  # Kentville Migratory Bird Sanctuary
    set_key CA-1781 VEFF-3860  # Kluscap Wilderness Area
    set_key CA-1782 VEFF-2344  # Lake Egmont Nature Reserve
    set_key CA-1783 VEFF-3862  # Lake Rossignol Wilderness Area
    set_key CA-1784 VEFF-3863  # Lambs Lake Nature Reserve
    set_key CA-1785 VEFF-1459  # Liscomb River Wilderness Area
    set_key CA-1786 VEFF-3865  # Little Beaver Lakes Nature Reserve
    set_key CA-1788 VEFF-3866  # Long Lake Nature Reserve
    set_key CA-1789 VEFF-3868  # Lyons Marsh Nature Reserve
    set_key CA-1790 VEFF-3870  # MacAulays Hill Nature Reserve
    set_key CA-1791 VEFF-1460  # MacElmons Pond Provincial Park
    set_key CA-1792 VEFF-3872  # MacFarlane Woods Nature Reserve
    set_key CA-1793 VEFF-3873  # MacKay Brook Nature Reserve
    set_key CA-1794 VEFF-1462  # Marie Joseph Provincial Park
    set_key CA-1795 VEFF-1863  # Margaree River Wilderness Area
    set_key CA-1796 VEFF-3877  # Martin Brook Nature Reserve
    set_key CA-1798 VEFF-3879  # Masons Mountain Nature Reserve
    set_key CA-1799 VEFF-1463  # McCormacks Beach Provincial Park
    set_key CA-1800 VEFF-1864  # McGill Lake Wilderness Area
    set_key CA-1801 VEFF-3881  # Medway Lakes Wilderness Area
    set_key CA-1803 NIL-0000  # Middle River Framboise Wilderness Area; WWFF candidates: VEFF-1464, VEFF-3880
    set_key CA-1804 VEFF-3882  # Montrose Nature Reserve
    set_key CA-1805 VEFF-1465  # Moose River Gold Mines Provincial Park
    set_key CA-1808 VEFF-3883  # North Mountain Wilderness Area
    set_key CA-1810 VEFF-1468  # Northport Beach Provincial Park
    set_key CA-1811 VEFF-3884  # Northwest Brook Nature Reserve
    set_key CA-1812 VEFF-3885  # Ogden Round Lake Wilderness Area
    set_key CA-1813 VEFF-2349  # Old Annapolis Road Nature Reserve
    set_key CA-1815 VEFF-3888  # Petite Bog Nature Reserve
    set_key CA-1816 VEFF-2351  # Pockwock Wilderness Area
    set_key CA-1818 VEFF-2353  # Polletts Cove - Aspy Fault Wilderness Area
    set_key CA-1819 VEFF-1867  # Polly Brook Wilderness Area
    set_key CA-1820 VEFF-3889  # Ponhook Lake Nature Reserve
    set_key CA-1821 VEFF-3891  # Porcupine Lake Wilderness Area
    set_key CA-1822 VEFF-1469  # Port Hebert Migratory Bird Sanctuary
    set_key CA-1823 VEFF-1470  # Port Joli Migratory Bird Sanctuary
    set_key CA-1824 VEFF-3892  # Port L'Hebert Nature Reserve
    set_key CA-1825 VEFF-3893  # Port La Tour Bogs Wilderness Area
    set_key CA-1826 VEFF-1868  # Portapique River Wilderness Area
    set_key CA-1827 VEFF-2355  # Quinns Meadow Nature Reserve
    set_key CA-1828 VEFF-1473  # Raven Head Wilderness Area
    set_key CA-1829 VEFF-3895  # Rawdon River Nature Reserve
    set_key CA-1830 VEFF-3897  # River Inhabitants Nature Reserve
    set_key CA-1832 VEFF-3898  # Rogues Roost Wilderness Area
    set_key CA-1833 VEFF-3899  # Roman Valley Nature Reserve
    set_key CA-1834 VEFF-4818  # Roseway River Wilderness Area
    set_key CA-1835 VEFF-3900  # Ruiss Noir Wilderness Area
    set_key CA-1836 VEFF-3901  # Rush Lake Nature Reserve
    set_key CA-1837 VEFF-1869  # Sable River Migratory Bird Sanctuary
    set_key CA-1838 VEFF-3902  # Sackville River Protected Area
    set_key CA-1839 VEFF-1475  # Scatarie Island Wilderness Area
    set_key CA-1840 VEFF-3903  # Scrag Lake Wilderness Area
    set_key CA-1841 VEFF-3904  # Seal Cove Nature Reserve
    set_key CA-1842 VEFF-3905  # Seven Falls Nature Reserve
    set_key CA-1847 VEFF-3907  # Ship Harbour Long Lake Wilderness Area
    set_key CA-1848 VEFF-2875  # Shubie Park Wilderness Area
    set_key CA-1849 VEFF-1476  # Shubenacadie Provincial Wildlife Park
    set_key CA-1850 VEFF-1479  # Sugarloaf Mountain Wilderness Area
    set_key CA-1854 VEFF-3908  # Sixth and Coades Lakes Nature Reserve
    set_key CA-1855 VEFF-3909  # Skull Bog Lake Nature Reserve
    set_key CA-1856 VEFF-3910  # Slade Lake Nature Reserve
    set_key CA-1857 VEFF-3911  # Sloans Lake Nature Reserve
    set_key CA-1858 VEFF-3912  # Smith Lake Nature Reserve
    set_key CA-1859 VEFF-3913  # Snowshoe Lakes Nature Reserve
    set_key CA-1861 VEFF-3914  # South Panuke Wilderness Area
    set_key CA-1862 VEFF-3915  # South River Nature Reserve
    set_key CA-1863 VEFF-4346  # Southern Bight-Minas Basin Ramsar Site
    set_key CA-1864 VEFF-3916  # Southwest Mabou River Nature Reserve
    set_key CA-1865 VEFF-3917  # Spinneys Heath Nature Reserve
    set_key CA-1866 VEFF-3918  # Sporting Lake Nature Reserve
    set_key CA-1867 VEFF-3919  # Spry Bay Provincial Park
    set_key CA-1873 VEFF-3920  # Steepbank Brook Nature Reserve
    set_key CA-1876 VEFF-1859  # Irish Cove Provincial Park
    set_key CA-1878 VEFF-3921  # Tait Lake Nature Reserve
    set_key CA-1879 VEFF-1480  # Tangier Grand Lake Wilderness Area
    set_key CA-1880 VEFF-1481  # Tatamagouche Provincial Park
    set_key CA-1882 VEFF-1482  # Ten Mile Lake Provincial Park
    set_key CA-1883 VEFF-3922  # Tennycape River Nature Reserve
    set_key CA-1884 VEFF-1483  # Terence Bay Wilderness Area
    set_key CA-1885 VEFF-1484  # The Big Bog Wilderness Area
    set_key CA-1886 VEFF-4808  # Lower East Chezzetcook Provincial Park
    set_key CA-1887 VEFF-3923  # The Stillwaters Wilderness Area
    set_key CA-1888 VEFF-3924  # Tiddville Nature Reserve
    set_key CA-1890 VEFF-1485  # Toadfish Lakes Wilderness Area
    set_key CA-1892 VEFF-3925  # Tobeatic Wilderness Area
    set_key CA-1893 VEFF-1865  # Open Hearth Park Recreation Park
    set_key CA-1894 VEFF-3926  # Torbrook Nature Reserve
    set_key CA-1897 VEFF-1486  # Trout Brook Wilderness Area
    set_key CA-1898 VEFF-3927  # Tupper Lake Nature Reserve
    set_key CA-1900 VEFF-3929  # Tusket River Wilderness Area
    set_key CA-1903 VEFF-3928  # Tusket River Nature Reserve
    set_key CA-1905 VEFF-3930  # Twelve Mile Stream Wilderness Area
    set_key CA-1907 VEFF-3931  # Walton River Wilderness Area
    set_key CA-1909 VEFF-1487  # Waverley - Salmon River Long Lake Wilderness Area Wilderness Area
    set_key CA-1910 VEFF-3933  # Wentworth Lake Nature Reserve
    set_key CA-1911 VEFF-3934  # Wentworth Valley Wilderness Area
    set_key CA-1912 VEFF-3935  # West Branch Medway River Nature Reserve
    set_key CA-1913 VEFF-1488  # West Dover Provincial Park Reserve
    set_key CA-1915 VEFF-1489  # White Lake Wilderness Area
    set_key CA-1916 VEFF-1919  # Reserve Naturelle de l'Abbaye-Cistercienne-de-Rougemont
    set_key CA-1917 VEFF-4870  # Réserve naturelle de l'Académie-des-Sacrés-Coeurs
    set_key CA-1918 VEFF-1525  # Réserve écologique de l'Aigle-à-Tête-Blanche
    set_key CA-1919 VEFF-1917  # Reserve Naturelle Alton-E.-Peck
    set_key CA-1920 VEFF-3957  # Réserve naturelle de l'Alvar-d'Aylmer (Sec. CNQ)
    set_key CA-1921 VEFF-1918  # Reserve Naturelle Amala
    set_key CA-1923 VEFF-1892  # Reserve ecologique Andre-Linteau
    set_key CA-1924 VEFF-1893  # Reserve ecologique Andre-Michaux
    set_key CA-1925 VEFF-2511  # Annedda
    set_key CA-1926 VEFF-2506  # Annemarie-Zeiss-Kunerth
    set_key CA-1927 VEFF-2513  # Archipel-du-Mitan
    set_key CA-1928 VEFF-2501  # Ashuapmushuan
    set_key CA-1930 VEFF-2461  # Baie aux Feuilles
    set_key CA-1931 VEFF-2360  # Baie de Brador Migratory Bird Sanctuary
    set_key CA-1932 VEFF-2514  # Baie de Mille Vaches
    set_key CA-1933 VEFF-2515  # Baie-des-Brises
    set_key CA-1934 VEFF-2361  # Baie des Loups Migratory Bird Sanctuary
    set_key CA-1935 VEFF-2507  # Barbara-Burrowes-Buchanan
    set_key CA-1936 VEFF-2519  # Battures-de-Saint-Augustin-de-Desmaures
    set_key CA-1938 VEFF-1494  # Beaureal Reserve Naturelle
    set_key CA-1939 VEFF-2362  # Betchouane Migratory Bird Sanctuary
    set_key CA-1941 VEFF-2479  # Bog-a-Lanieres
    set_key CA-1942 VEFF-2523  # Bois-Angell
    set_key CA-1943 VEFF-2524  # Bois-Barre-de-Villieu
    set_key CA-1945 VEFF-1499  # Chateau Frontenac National Historic Site
    set_key CA-1946 NIL-0000  # Réserve naturelle du Bois-des-Patriotes (Par. Mathieu-Nord); WWFF candidates: VEFF-2525, VEFF-2526
    set_key CA-1947 VEFF-2527  # Boise-de-l'equerre
    set_key CA-1948 VEFF-2528  # Boise-de-la-Pointe-Saint-Gilles
    set_key CA-1949 VEFF-4003  # Réserve naturelle du Boisé-des-Blouin
    set_key CA-1950 VEFF-4004  # Réserve naturelle du Boisé-des-Douze
    set_key CA-1951 VEFF-1907  # Reserve ecologique du Boise-des-Muir
    set_key CA-1954 VEFF-2373  # Parc de la Maison-des-Gouverneurs National Historical Site
    set_key CA-1955 VEFF-1516  # Parc de la Poite-Valaine
    set_key CA-1956 NIL-0000  # Réserve naturelle du Boisé-Papineau (Sec. ACBP); WWFF candidates: VEFF-4881, VEFF-4882, VEFF-4883
    set_key CA-1957 VEFF-1872  # Centre de plein air Roger-Cabana
    set_key CA-1958 VEFF-1874  # Domaine Laurentien
    set_key CA-1959 VEFF-2529  # Boise-Roger-Lemoine
    set_key CA-1960 VEFF-2802  # Boatswain Bay Migratory Bird Sanctuary
    set_key CA-1961 VEFF-2363  # Bonaventure Island and Perce Rock Migratory Bird Sanctuary
    set_key CA-1963 VEFF-3951  # Réserve naturelle Brecht
    set_key CA-1965 VEFF-4009  # Réserve naturelle du Canton-de-Shefford
    set_key CA-1966 VEFF-2364  # Canyon Sainte Anne
    set_key CA-1967 VEFF-2365  # Cap Saint Ignace Migratory Bird Sanctuary
    set_key CA-1968 VEFF-1902  # Reserve ecologique des Caribous-de-Jourdan
    set_key CA-1970 VEFF-2366  # Carillon Island Migratory Bird Sanctuary
    set_key CA-1971 VEFF-3952  # Réserve naturelle Carmen-Lavoie
    set_key CA-1972 VEFF-1873  # Centre recreatif du Lac Echo
    set_key CA-1975 VEFF-1894  # Reserve ecologique Charles-B.-Banville
    set_key CA-1976 VEFF-3953  # Réserve naturelle Charles-Gale
    set_key CA-1978 VEFF-2463  # Chenaie-des-Iles-Finlay
    set_key CA-1979 VEFF-1895  # Reserve ecologique Chicobi
    set_key CA-1980 VEFF-1896  # Reserve ecologique Claude-Melancon
    set_key CA-1981 VEFF-3955  # Réserve naturelle Colby
    set_key CA-1983 VEFF-1875  # Espace vert Louis-Morin
    set_key CA-1984 VEFF-1876  # Parc Basler
    set_key CA-1985 VEFF-4831  # Collines-Ondulées National Park Reserve (QC)
    set_key CA-1986 VEFF-2377  # Corossol Island Migratory Bird Sanctuary
    set_key CA-1987 VEFF-4012  # Réserve naturelle du Coteau-de-la-Rivière-La Guerre
    set_key CA-1988 VEFF-1897  # Reserve ecologique de Couchepaganiche
    set_key CA-1990 VEFF-3968  # Réserve naturelle de la Coulée-des-Érables
    set_key CA-1991 VEFF-2378  # Couvee Islands Migratory Bird Sanctuary
    set_key CA-1992 VEFF-3969  # Réserve naturelle de la Cumberland
    set_key CA-1993 VEFF-3956  # Réserve naturelle David-Schwartz
    set_key CA-1995 VEFF-3995  # Réserve naturelle des Demoiselles
    set_key CA-1996 VEFF-2454  # Deux Montagnes Preserve
    set_key CA-1997 VEFF-3383  # Dorchester Square
    set_key CA-1998 VEFF-1903  # Reserve ecologique des Dunes-de-Berry
    set_key CA-1999 VEFF-1904  # Reserve ecologique des Dunes-de-la-Moraine-d'Harricana
    set_key CA-2004 VEFF-2462  # Erabliere-du-Trente-et-Un-Milles
    set_key CA-2005 VEFF-1909  # Reserve ecologique Ernest-Lepage
    set_key CA-2006 VEFF-3960  # Réserve naturelle de l'Estuaire-de-la-Petite-Rivière-Cascapédia
    set_key CA-2008 VEFF-3961  # Réserve naturelle de l'Estuaire-de-la-Rivière-York
    set_key CA-2009 VEFF-3970  # Réserve naturelle de la Falaise
    set_key CA-2010 VEFF-1910  # Reserve ecologique Fernald
    set_key CA-2011 VEFF-3971  # Réserve naturelle de la Forêt-de-Senneville
    set_key CA-2012 VEFF-2516  # Foret-du-Grand-Coteau
    set_key CA-2013 VEFF-1900  # Reserve ecologique de la Foret-la-Blanche
    set_key CA-2016 VEFF-1877  # Parc Chante Bois
    set_key CA-2017 VEFF-1878  # Parc Chopin
    set_key CA-2018 VEFF-1911  # Reserve ecologique G.-Oscar-Villeneuve
    set_key CA-2020 VEFF-2509  # Gault-de-l'Universite McGill
    set_key CA-2021 VEFF-2456  # Refuge faunique de la Grande-Île
    set_key CA-2022 VEFF-1908  # Reserve ecologique du Grand-Lac-Sale
    set_key CA-2023 VEFF-1901  # Reserve ecologique de la Grande-Riviere
    set_key CA-2025 VEFF-1879  # Parc de la Coulee
    set_key CA-2026 VEFF-1880  # Parc du Clos-Fourtet
    set_key CA-2027 VEFF-1881  # Parc du Corridor Aerobique
    set_key CA-2028 VEFF-1883  # Parc Henri-Piette
    set_key CA-2029 VEFF-1884  # Parc Irenee-Benoit
    set_key CA-2030 VEFF-1905  # Reserve ecologique des Grands-Ormes
    set_key CA-2031 VEFF-2374  # Gros Mecatina Migratory Bird Sanctuary
    set_key CA-2033 VEFF-1885  # Parc Leon-Arcand
    set_key CA-2034 VEFF-1886  # Parc Lineaire Le P'tit Train du Nord
    set_key CA-2038 VEFF-2375  # Ile a la Brume Migratory Bird Sanctuary
    set_key CA-2040 VEFF-2376  # Ile aux Herons Migratory Bird Sanctuary
    set_key CA-2041 VEFF-1898  # Réserve naturelle de l'Île-Beauregard
    set_key CA-2043 VEFF-1891  # Perce UNESCO Geopark
    set_key CA-2044 VEFF-2510  # Ile-Bonfoin
    set_key CA-2045 VEFF-3408  # Parc Hervé-Larivière
    set_key CA-2046 VEFF-1887  # Parc Parent
    set_key CA-2047 VEFF-3963  # Réserve naturelle de l'île de Grace
    set_key CA-2048 VEFF-1888  # Parc Prevost
    set_key CA-2049 VEFF-1890  # Parc Val-des-Monts
    set_key CA-2050 VEFF-1899  # Reserve ecologique de l'Ile-Garth
    set_key CA-2052 VEFF-1519  # Parc du Vieux-Moulin de Pointe-aux-Trembles
    set_key CA-2053 VEFF-1517  # Parc des Cascades de Rawdon
    set_key CA-2054 VEFF-1524  # Refuge faunique de l'Ile-Laval
    set_key CA-2059 VEFF-1906  # Reserve ecologique des Iles-Avelle-Wight-et-Hiam
    set_key CA-2062 VEFF-2379  # Iles de la Paix Migratory Bird Sanctuary
    set_key CA-2063 VEFF-2542  # Iles Sainte Marie Migratory Bird Sanctuary
    set_key CA-2064 VEFF-2455  # Ilet aux Alouettes Preserve
    set_key CA-2066 VEFF-1912  # Reserve ecologique Irene-Fournier
    set_key CA-2067 VEFF-1913  # Reserve ecologique Irenee-Marie
    set_key CA-2068 VEFF-2380  # Isle Verte Migratory Bird Sanctuary
    set_key CA-2069 VEFF-2381  # Islet Migratory Bird Sanctuary
    set_key CA-2070 VEFF-1914  # Reserve ecologique J.-Clovis-Laflamme
    set_key CA-2071 VEFF-1915  # Reserve ecologique Jackrabbit
    set_key CA-2073 VEFF-1916  # Reserve ecologique James-Little
    set_key CA-2074 VEFF-2537  # Jean-Paul-Riopelle
    set_key CA-2076 VEFF-2486  # Judith-De Bresoles
    set_key CA-2077 VEFF-2487  # Jules-Carpentier
    set_key CA-2079 VEFF-2476  # Kettles-de-Berry
    set_key CA-2081 VEFF-2472  # Lac-a-la-Tortue
    set_key CA-2083 VEFF-2415  # Parc du Lac-Beauchamp (Lac Beauchamp)
    set_key CA-2085 VEFF-4884  # Réserve naturelle du Lac-Brais
    set_key CA-2087 VEFF-4886  # Réserve naturelle du Lac-Breeches (Sector 1)
    set_key CA-2088 VEFF-4887  # Réserve naturelle du Lac-Breeches NE PAS ACTIVER (Sector 2)
    set_key CA-2089 VEFF-2530  # Lac-Brule Natrue Reserve
    set_key CA-2090 VEFF-4888  # Réserve naturelle du Lac-Clair-de-Perthuis
    set_key CA-2096 VEFF-2369  # Lac-Gale
    set_key CA-2100 VEFF-2480  # Lac-Malakisis
    set_key CA-2106 VEFF-2460  # Lacs Vaudray et Joannes
    set_key CA-2109 VEFF-2488  # Leon-Provancher
    set_key CA-2110 VEFF-2489  # Lionel-Cinq-Mars
    set_key CA-2111 VEFF-2490  # Louis-Babel
    set_key CA-2112 VEFF-2491  # Louis-Ovide-Brunet
    set_key CA-2113 VEFF-2492  # Louis-Zephirin-Rousseau
    set_key CA-2116 VEFF-2393  # Parc Bouvrette Recreation Park
    set_key CA-2120 VEFF-2520  # Marais-du-Nord
    set_key CA-2121 VEFF-1920  # Sommet Morin Heights
    set_key CA-2122 VEFF-2390  # Parc Arthur-Helms Recreation Park
    set_key CA-2124 VEFF-2531  # Marais-Leon-Provancher
    set_key CA-2126 VEFF-2493  # Marcel-Leger
    set_key CA-2127 VEFF-2494  # Réserve écologique Marcel-Raymond
    set_key CA-2128 VEFF-2495  # Marcelle-Gauvreau
    set_key CA-2130 VEFF-2496  # Marie-Jean-Eudes
    set_key CA-2131 VEFF-2464  # Réserve écologique de la Matamec
    set_key CA-2132 VEFF-2538  # Réserve naturelle Materne
    set_key CA-2133 VEFF-2532  # Meandre-de-la-Riviere-Vincelotte
    set_key CA-2135 VEFF-1529  # Réserve écologique du Micocoulier
    set_key CA-2138 VEFF-2465  # Réserve écologique de la Mine-aux-Pipistrelles
    set_key CA-2140 VEFF-2399  # Parc de la commune et territoire du ruisseau Saint-Jean
    set_key CA-2143 VEFF-2402  # Parc de la Prucheraie
    set_key CA-2144 VEFF-2405  # Parc de la Vieille-École
    set_key CA-2145 VEFF-2406  # Parc Ludger-Duvernay - St-Jérome
    set_key CA-2147 VEFF-2420  # Parc Henri-Daoust
    set_key CA-2150 VEFF-2425  # Parc Maurice-St-Pierre
    set_key CA-2151 VEFF-2387  # Mont-Saint-Hilaire Migratory Bird Sanctuary
    set_key CA-2152 VEFF-2473  # Réserve écologique de Mont-Saint-Pierre
    set_key CA-2154 VEFF-2426  # Parc Melançon
    set_key CA-2155 VEFF-2427  # Parc Michaël-Desbiens
    set_key CA-2156 VEFF-3972  # Réserve naturelle de la Montagne-de-Rigaud
    set_key CA-2159 VEFF-2431  # Parc nature du Lac-Jérôme
    set_key CA-2160 VEFF-2451  # Parc Schulz
    set_key CA-2161 VEFF-2452  # Parc Saint-Georges
    set_key CA-2162 VEFF-2470  # Réserve écologique de la Tourbière-de-Shannon
    set_key CA-2163 VEFF-2474  # Réserve écologique de Ristigouche
    set_key CA-2164 VEFF-2388  # Montmagny Migratory Bird Sanctuary
    set_key CA-2169 VEFF-2389  # Nicolet Migratory Bird Sanctuary
    set_key CA-2172 VEFF-2394  # Parc Christopher Recreation Park
    set_key CA-2173 VEFF-2533  # Parc-des-Falaises
    set_key CA-2174 VEFF-2416  # Parc du Mont-Comi
    set_key CA-2176 VEFF-2421  # Parc Jean-Drapeau
    set_key CA-2177 VEFF-4021  # Réserve naturelle du Parc-Languedoc
    set_key CA-2179 VEFF-2481  # Réserve écologique du Mont-Gosford
    set_key CA-2180 VEFF-4043  # Réserve naturelle Patrick-Deehy
    set_key CA-2181 VEFF-4023  # Réserve naturelle du Patrimoine-des-Hébert
    set_key CA-2182 VEFF-4000  # Réserve naturelle des Pays-d'en-Haut
    set_key CA-2183 VEFF-2508  # Réserve naturelle Claudia-Duchâteau
    set_key CA-2184 VEFF-2482  # Réserve écologique du Père-Louis-Marie
    set_key CA-2186 VEFF-4025  # Réserve naturelle du Petit-Canal-à-Salaberry-de-Valleyfield
    set_key CA-2187 VEFF-2534  # Réserve naturelle du Petit-Domaine-Walden
    set_key CA-2188 VEFF-2453  # Philipsburg Migratory Bird Sanctuary
    set_key CA-2190 VEFF-2512  # Réserve naturelle de l'Anse-Ross
    set_key CA-2191 VEFF-2517  # Réserve naturelle de la Rivière-à-la-Loutre
    set_key CA-2195 VEFF-2483  # Pin-Rigide
    set_key CA-2201 VEFF-2457  # Refuge faunique de Pointe-du-Lac
    set_key CA-2202 VEFF-3978  # Réserve naturelle de la Pointe-Fontaine
    set_key CA-2203 VEFF-1526  # Réserve écologique de la Pointe-Heath
    set_key CA-2204 VEFF-1528  # Réserve écologique de Pointe-Platon
    set_key CA-2205 VEFF-4001  # Réserve naturelle des Pointes
    set_key CA-2206 VEFF-2535  # Polatouche-de-Villieu
    set_key CA-2207 VEFF-2536  # Pont-a-Chevilles
    set_key CA-2208 VEFF-1530  # Port-Cartier-Sept-Iles
    set_key CA-2209 VEFF-2502  # Port-Daniel Reserve
    set_key CA-2211 VEFF-2503  # Portneuf Reserve Faunique
    set_key CA-2212 VEFF-2466  # Presqu'ile Robillard
    set_key CA-2215 VEFF-1532  # Reserve naturelle de l'Ile-aux-Basques-et-des-Razades
    set_key CA-2216 VEFF-1533  # Reserve naturelle de l'Ile-aux-Pommes
    set_key CA-2217 VEFF-1531  # Reserve naturelle de l'Ile-Kettle
    set_key CA-2218 VEFF-2504  # Rimouski
    set_key CA-2220 VEFF-2501  # Riviere Ashuapmushuan
    set_key CA-2221 VEFF-2467  # Réserve écologique de la Rivière-aux-Brochets
    set_key CA-2222 VEFF-3979  # Réserve naturelle de la Rivière-Bleury (Sec. CIME / Par. Ferme-Simard)
    set_key CA-2224 VEFF-2518  # Riviere-du-Diable
    set_key CA-2225 VEFF-2468  # Réserve écologique de la Rivière-du-Moulin
    set_key CA-2229 VEFF-2469  # Riviere-Rouge
    set_key CA-2231 VEFF-2540  # Rochers aux Oiseaux Migratory Bird Sanctuary
    set_key CA-2232 VEFF-2497  # Rolland-Germain
    set_key CA-2235 VEFF-2484  # Ruisseau-de-l'Indien
    set_key CA-2240 VEFF-2541  # Saint Augustin Migratory Bird Sanctuary
    set_key CA-2242 VEFF-2505  # Saint-Maurice
    set_key CA-2243 VEFF-2543  # Saint-Omer Migratory Bird Sanctuary
    set_key CA-2244 VEFF-2544  # Saint-Vallier Migratory Bird Sanctuary
    set_key CA-2246 VEFF-2545  # Senneville Migratory Bird Sanctuary
    set_key CA-2248 NIL-0000  # Réserve naturelle de la Serpentine (Sec. Bricault-Cordeau); WWFF candidates: VEFF-4873, VEFF-4874, VEFF-4875, VEFF-4876
    set_key CA-2249 VEFF-3943  # Parc Le Rocher
    set_key CA-2250 VEFF-2930  # Fort Richelieu National Historic Site
    set_key CA-2252 VEFF-1527  # Réserve écologique de la Serpentine-de-Coleraine
    set_key CA-2256 VEFF-2475  # Réserve écologique de Tantaré
    set_key CA-2257 VEFF-2498  # Tapani
    set_key CA-2258 VEFF-2522  # Terres-Noyees-de-la-Riviere-Noire
    set_key CA-2260 VEFF-2499  # Thomas-Fortin
    set_key CA-2261 VEFF-2485  # Thomas-Sterry-Hunt International
    set_key CA-2266 VEFF-3420  # Parc Pierre-Arpin
    set_key CA-2268 NIL-0000  # Réserve naturelle de la Tourbière-de-Venise-Ouest (Sec. SCCN / Par. Sauro(don), Neville-Kerr, Sauro(Beaux-Chalets)); WWFF candidates: VEFF-3986, VEFF-3987
    set_key CA-2270 NIL-0000  # Réserve naturelle de la Tourbière-du-Lac-à-la-Tortue (Sec. CNQ / Par. AbitibiConsolidated, Abitibi-Phase2); WWFF candidates: VEFF-3988, VEFF-3989
    set_key CA-2272 VEFF-2477  # Tourbieres-de-Lanoraie
    set_key CA-2273 VEFF-1921  # Trois-Saumons Migratory Bird Sanctuary
    set_key CA-2276 VEFF-2471  # Vallee-du-Ruiter
    set_key CA-2277 VEFF-2500  # Victor-A.-Huard
    set_key CA-2278 VEFF-2478  # Vieux-Arbres
    set_key CA-2282 VEFF-1540  # William Baldwin
    set_key CA-2284 VEFF-2539  # William-R.-J.-Oliver
    set_key CA-2372 VEFF-1541  # Alonsa Wildlife Management Area
    set_key CA-2374 VEFF-2602  # Armit Meadows Ecological Reserve
    set_key CA-2375 VEFF-4122  # Asatiwisipe Aki Traditional Use Planning Area
    set_key CA-2376 VEFF-2603  # Assiniboine Corridor Wildlife Management Area
    set_key CA-2377 VEFF-2605  # Baralzon Lake Ecological Reserve
    set_key CA-2378 VEFF-4961  # Basket Lake Wildlife Management Area
    set_key CA-2379 VEFF-4123  # Bell and Steeprock Canyons Protected Area
    set_key CA-2380 VEFF-4962  # Bernice Wildlife Management Area
    set_key CA-2382 VEFF-1962  # Birch River Ecological Reserve
    set_key CA-2384 VEFF-4124  # Brandon Hills Wildlife Management Area
    set_key CA-2385 VEFF-4125  # Broad Valley Wildlife Management Area
    set_key CA-2386 VEFF-4127  # Brokenhead River Ecological Reserve
    set_key CA-2387 VEFF-4128  # Brokenhead Wetland Ecological Reserve
    set_key CA-2388 VEFF-4964  # Broomhill Wildlife Management Area
    set_key CA-2389 VEFF-4129  # C. Stuart Stevenson Wildlife Management Area
    set_key CA-2391 VEFF-4965  # Catfish Creek Wildlife Management Area
    set_key CA-2392 VEFF-4130  # Cayer Wildlife Management Area
    set_key CA-2393 VEFF-4131  # Cedar Bog Ecological Reserve
    set_key CA-2396 VEFF-4967  # Clematis Wildlife Management Area
    set_key CA-2398 VEFF-4132  # Cowan Bog Ecological Reserve
    set_key CA-2399 VEFF-4134  # Deerwood Wildlife Management Area
    set_key CA-2400 NIL-0000  # Delta Marsh Wildlife Management Area; WWFF candidates: VEFF-0537, VEFF-1542
    set_key CA-2402 VEFF-4135  # Dog Lake Wildlife Management Area
    set_key CA-2403 VEFF-1543  # Douglas Marsh Wildlife Management Area
    set_key CA-2406 VEFF-4970  # Ebor Wildlife Management Area
    set_key CA-2408 VEFF-3011  # Ernie O' Dowda Recreation Park
    set_key CA-2411 VEFF-3016  # Fort Douglas Recreation Park
    set_key CA-2414 VEFF-4978  # Gerald W. Malaher Wildlife Management Area
    set_key CA-2415 VEFF-4980  # Grahamdale Wildlife Management Area
    set_key CA-2417 VEFF-4138  # Grant's Lake Wildlife Management Area
    set_key CA-2418 VEFF-4981  # Gypsumville Wildlife Management Area
    set_key CA-2419 VEFF-4983  # Harperville Wildlife Management Area
    set_key CA-2420 VEFF-4984  # Harrison Wildlife Management Area
    set_key CA-2422 VEFF-4139  # Hilbre Wildlife Management Area
    set_key CA-2423 VEFF-4140  # Holmfield Wildlife Management Area
    set_key CA-2424 VEFF-4141  # Holmgren Pines Ecological Reserve
    set_key CA-2425 VEFF-4987  # Inwood Wildlife Management Area
    set_key CA-2426 VEFF-1963  # Jennifer and Tom Shay Ecological Reserve
    set_key CA-2427 VEFF-4143  # Kaskatamagan Sipi Wildlife Management Area
    set_key CA-2428 VEFF-4144  # Kaskatamagan Wildlife Management Area
    set_key CA-2429 VEFF-4145  # Kaweenakumik Islands Ecological Reserve
    set_key CA-2430 VEFF-2610  # Kildonan Recreation Park
    set_key CA-2431 VEFF-3026  # King Edward Recreation Park
    set_key CA-2432 VEFF-2611  # King's Park Recreation Park
    set_key CA-2433 VEFF-3027  # Lagimodiere-Gaboury Park Wildlife Management Area
    set_key CA-2434 VEFF-4137  # Dr. Frank Baldwin WMA
    set_key CA-2435 VEFF-1964  # Lake St. George Caves Ecological Reserve
    set_key CA-2436 VEFF-4147  # Lake Winnipegosis Salt Flats Ecological Reserve
    set_key CA-2439 VEFF-4148  # Langruth Wildlife Management Area
    set_key CA-2440 VEFF-4989  # Lauder Sandhills Wildlife Management Area
    set_key CA-2441 VEFF-4990  # Lee Lake Wildlife Management Area
    set_key CA-2442 VEFF-4149  # Lee River Wildlife Management Area
    set_key CA-2445 VEFF-4150  # Lewis Bog Ecological Reserve
    set_key CA-2447 VEFF-4151  # Libau Bog Ecological Reserve
    set_key CA-2448 VEFF-4152  # Little Birch Wildlife Management Area
    set_key CA-2449 VEFF-4153  # Little George Island Ecological Reserve
    set_key CA-2450 VEFF-4991  # Little Grand Rapids First Nation Traditional Use Wildlife Management Area
    set_key CA-2451 VEFF-4154  # Little Saskatchewan River Wildlife Management Area
    set_key CA-2452 VEFF-1965  # Long Point Ecological Reserve
    set_key CA-2453 VEFF-4993  # Lundar Wildlife Management Area
    set_key CA-2455 VEFF-4156  # Mantagao Lake Wildlife Management Area
    set_key CA-2457 VEFF-4157  # Mars Hill Wildlife Management Area
    set_key CA-2458 VEFF-4158  # Marshy Point Wildlife Management Area
    set_key CA-2460 VEFF-4999  # Moose Creek Wildlife Management Area
    set_key CA-2461 VEFF-5000  # Moosehorn Wildlife Management Area
    set_key CA-2464 VEFF-1546  # Narcisse Provincial Park
    set_key CA-2470 VEFF-1548  # Oak Hammock Marsh
    set_key CA-2471 VEFF-4159  # Observation Point Wildlife Management Area
    set_key CA-2472 VEFF-4160  # Onanole Wildlife Management Area
    set_key CA-2473 VEFF-2616  # Otter Lake Wildlife Management Area
    set_key CA-2474 VEFF-1966  # Palsa Hazel Ecological Reserve
    set_key CA-2475 VEFF-3034  # Parc Joseph Royal Wildlife Management Area
    set_key CA-2476 VEFF-4161  # Parkland Wildlife Management Area
    set_key CA-2478 VEFF-4760  # Pimachiowin Aki WMA
    set_key CA-2479 VEFF-1549  # Pelican Islands Park Reserve
    set_key CA-2480 VEFF-4162  # Pembina Valley Wildlife Management Area
    set_key CA-2483 VEFF-1550  # Pemmican Island Park Reserve
    set_key CA-2484 VEFF-4163  # Peonan Point Wildlife Management Area
    set_key CA-2485 VEFF-5011  # Pierson Wildlife Management Area
    set_key CA-2487 VEFF-4444  # Piney Ecological Reserve
    set_key CA-2488 VEFF-4164  # Pocock Lake Ecological Reserve
    set_key CA-2489 VEFF-5013  # Point River Wildlife Management Area
    set_key CA-2493 VEFF-4165  # Portage Sandhills Wildlife Management Area
    set_key CA-2494 VEFF-4166  # Proulx Lake Wildlife Management Area
    set_key CA-2495 VEFF-2618  # Proven Lake Wildlife Management Area
    set_key CA-2496 VEFF-3038  # Provencher Park Wildlife Management Area
    set_key CA-2497 VEFF-3040  # Rat River Wildlife Management Area
    set_key CA-2498 VEFF-5036  # Red Deer Wildlife Management Area
    set_key CA-2499 VEFF-2619  # Red Rock Ecological Reserve
    set_key CA-2500 VEFF-4167  # Reindeer Island Ecological Reserve
    set_key CA-2501 VEFF-5037  # Rembrandt Wildlife Management Area
    set_key CA-2502 VEFF-4168  # Riverside Wildlife Management Area
    set_key CA-2506 VEFF-5042  # Saskeram Wildlife Management Area
    set_key CA-2507 VEFF-5044  # Sharpewood Wildlife Management Area
    set_key CA-2508 VEFF-4171  # Sleeve Lake Wildlife Management Area
    set_key CA-2509 VEFF-4172  # Souris River Bend Wildlife Management Area
    set_key CA-2510 VEFF-4173  # Spruce Woods Wildlife Management Area
    set_key CA-2511 VEFF-4174  # Spur Woods Wildlife Management Area
    set_key CA-2512 VEFF-4176  # Ste. Anne Bog Ecological Reserve
    set_key CA-2513 VEFF-4445  # St. Labre Bog Ecological Reserve
    set_key CA-2514 VEFF-4175  # St. Malo Wildlife Management Area
    set_key CA-2515 VEFF-2621  # St. Vital Park Recreation Park
    set_key CA-2516 VEFF-5047  # Steeprock Wildlife Management Area
    set_key CA-2518 VEFF-4177  # Stuartburn Wildlife Management Area
    set_key CA-2520 VEFF-4142  # John T. Williams WMA
    set_key CA-2521 VEFF-4178  # Tiger Hills Wildlife Management Area
    set_key CA-2522 VEFF-5051  # Tom Lamb Wildlife Management Area
    set_key CA-2523 VEFF-5053  # Turtle Mountain Wildlife Management Area
    set_key CA-2527 VEFF-3060  # Vimy Ridge Memorial Park Recreation Park
    set_key CA-2528 VEFF-4179  # Wakopa Wildlife Management Area
    set_key CA-2530 VEFF-1554  # Walter Cook Caves Ecological Reserve
    set_key CA-2531 VEFF-4180  # Wampum Ecological Reserve
    set_key CA-2533 VEFF-4133  # David G. Tomasson WMA
    set_key CA-2534 VEFF-4181  # Watson P. Davidson Wildlife Management Area
    set_key CA-2535 VEFF-5059  # Weiden Wildlife Management Area
    set_key CA-2536 VEFF-4182  # Wellington Wildlife Management Area
    set_key CA-2539 VEFF-4183  # Whitemouth Bog Ecological Reserve
    set_key CA-2541 VEFF-4184  # Whitemouth Island Ecological Reserve
    set_key CA-2542 VEFF-4185  # Whitemouth River Ecological Reserve
    set_key CA-2543 VEFF-4446  # Whitemud WMA
    set_key CA-2544 VEFF-1555  # Whitewater Lake Wildlife Management Area
    set_key CA-2546 VEFF-4186  # Woodridge Ecological Reserve
    set_key CA-2547 VEFF-1556  # Amisk Lake Ecological Reserve
    set_key CA-2548 VEFF-1557  # Anderson Island Recreation Site
    set_key CA-2554 VEFF-1558  # Backes Island Wildlife Refuge Recreation Site
    set_key CA-2558 VEFF-1559  # Basin and Middle Lakes Migratory Bird Sanctuary
    set_key CA-2565 VEFF-3069  # Beaver/Cowan Rivers Recreation Site
    set_key CA-2566 VEFF-4447  # Beaver Creek Conservation Area
    set_key CA-2571 VEFF-3731  # Besant Midden Protected Area
    set_key CA-2572 VEFF-2623  # Besant Recreation Site
    set_key CA-2573 VEFF-2624  # Besnard Lake Recreation Site
    set_key CA-2576 VEFF-4187  # Big Shell Recreation Site
    set_key CA-2578 VEFF-2626  # Big Valley Lake Ecological Reserve
    set_key CA-2579 VEFF-3732  # Birchbark Lake Recreation Site
    set_key CA-2581 VEFF-4188  # Bittern Lake Recreation Site
    set_key CA-2584 VEFF-4189  # Borden Bridge Recreation Site
    set_key CA-2608 VEFF-4195  # Coldwell Park Recreation Site
    set_key CA-2614 VEFF-4196  # Courtenay Lake Recreation Site
    set_key CA-2615 VEFF-4197  # Cowan Dam Recreation Site
    set_key CA-2616 VEFF-4198  # Cranberry Flats Conservation Area
    set_key CA-2630 VEFF-2627  # Dickens Lake Recreation Site
    set_key CA-2633 VEFF-4205  # Dore Lake Recreation Site
    set_key CA-2637 VEFF-1967  # Duncairn Reservoir Migratory Bird Sanctuary
    set_key CA-2639 VEFF-2628  # E. B. Campbell Game Preserve
    set_key CA-2645 VEFF-4208  # Elbow Harbour Recreation Site
    set_key CA-2667 VEFF-4212  # Glen Ewen Burial Mound
    set_key CA-2669 VEFF-2629  # Gordon Lake Recreation Site
    set_key CA-2676 VEFF-4213  # Greenbush River Recreation Site
    set_key CA-2679 VEFF-4214  # Gull Lake Recreation Site
    set_key CA-2689 VEFF-4216  # Heglund Island Recreation Site
    set_key CA-2692 VEFF-2632  # Hickson - Maribelli Lakes Pictographs Recreation Site
    set_key CA-2693 VEFF-2633  # Hidden Valley Wildlife Refuge
    set_key CA-2696 VEFF-1968  # Indian Head Migratory Bird Sanctuary
    set_key CA-2709 VEFF-5094  # Lac La Plonge Recreation Site
    set_key CA-2711 VEFF-1572  # Last Mountain Lake Migratory Bird Sanctuary
    set_key CA-2715 VEFF-4220  # Lemsford Ferry Tipi Rings
    set_key CA-2717 VEFF-1573  # Lenore Lake Migratory Bird Sanctuary
    set_key CA-2718 VEFF-3734  # Limestone Lake Recreation Site
    set_key CA-2719 VEFF-4221  # Little Amyot Lake Recreation Site
    set_key CA-2726 VEFF-4223  # Lovering Lake Recreation Site
    set_key CA-2728 VEFF-4224  # Macdowall Bog
    set_key CA-2729 VEFF-5096  # MacKay Lake Recreation Site
    set_key CA-2740 VEFF-2634  # Matador Provincial Pasture
    set_key CA-2741 VEFF-2635  # Matador Grasslands Protected Area
    set_key CA-2742 VEFF-2636  # Maurice Street Wildlife Sanctuary
    set_key CA-2750 VEFF-4225  # Meridian Creek Recreation Site
    set_key CA-2754 VEFF-4226  # Minton Turtle Effigy
    set_key CA-2763 VEFF-4227  # Mountain Cabin Recreation Site
    set_key CA-2765 VEFF-1971  # Murray Lake Migratory Bird Sanctuary
    set_key CA-2769 VEFF-1972  # Neely Lake Migratory Bird Sanctuary
    set_key CA-2772 VEFF-4228  # Nesslin Lake Recreation Site
    set_key CA-2781 VEFF-4230  # Ogema Boulder Effigy
    set_key CA-2783 VEFF-1974  # Old Wives Lake Migratory Bird Sanctuary
    set_key CA-2784 VEFF-1975  # Opuntia Lake Migratory Bird Sanctuary
    set_key CA-2786 VEFF-3735  # Outlook Recreation Site
    set_key CA-2790 VEFF-4232  # Pasquia Hills North Recreation Site
    set_key CA-2795 VEFF-4457  # Peggy McKercher Conservation Area
    set_key CA-2800 VEFF-4234  # Pine Island Trading Post
    set_key CA-2804 VEFF-4235  # Piprell Lake Recreation Site
    set_key CA-2809 VEFF-1575  # Primrose Lake Wildlife Refuge
    set_key CA-2819 VEFF-1976  # Redberry Lake Migratory Bird Sanctuary
    set_key CA-2820 VEFF-2639  # Regina Beach Provincial Pasture
    set_key CA-2821 VEFF-3733  # Condie Nature Refuge Recreation Site
    set_key CA-2829 VEFF-4229  # Nipekamew Sand Cliffs
    set_key CA-2830 VEFF-4237  # Round Lake Recreation Site
    set_key CA-2836 VEFF-4238  # Saskatchewan River Forks Recreation Site
    set_key CA-2838 VEFF-1977  # Scent Grass Lake Migratory Bird Sanctuary
    set_key CA-2839 VEFF-2642  # Scentgrass Lake Game Preserve
    set_key CA-2846 VEFF-1978  # Shell Lake Recreation Site Recreation Site
    set_key CA-2865 VEFF-1979  # Sutherland Migratory Bird Sanctuary
    set_key CA-2869 VEFF-4242  # Taylor Lake Recreation Site
    set_key CA-2873 VEFF-4243  # Thomas Battersby Recreation Site
    set_key CA-2877 VEFF-4246  # Tyrrell Lake Recreation Site
    set_key CA-2879 VEFF-2643  # Upper Rousay Lake Game Preserve
    set_key CA-2880 VEFF-2644  # Upper Rousay Lake Migratory Bird Sanctuary
    set_key CA-2883 VEFF-1980  # Val Marie Reservoir Migratory Bird Sanctuary
    set_key CA-2884 VEFF-2645  # Valeport Recreation Site
    set_key CA-2885 VEFF-2647  # Valjean Natural Area
    set_key CA-2887 VEFF-4459  # Victoria Park (Saskatoon)
    set_key CA-2890 VEFF-2648  # Wanuskewin Heritage Park National Historical Park
    set_key CA-2896 VEFF-2649  # Wascana Lake Migratory Bird Sanctuary
    set_key CA-2898 VEFF-2650  # Wascana Valley Natural Area
    set_key CA-2901 VEFF-4248  # Waskwei River Recreation Site
    set_key CA-2902 VEFF-4249  # Waterhen River Recreation Site
    set_key CA-2904 VEFF-4250  # Weyakwin Lake (Ramsey Bay) Recreation Site
    set_key CA-2905 VEFF-4251  # White Butte Trails Recreation Site
    set_key CA-2910 VEFF-2651  # Wilkie Regional Park Recreation Site
    set_key CA-2914 VEFF-5140  # Wollaston Lake (Hidden Bay) Recreation Site
    set_key CA-2917 VEFF-1981  # Woodlawn Regional Park Recreation Site
    set_key CA-2920 VEFF-1577  # Alexo Natural Area
    set_key CA-2921 VEFF-1578  # Alsike Bat Lake Natural Area
    set_key CA-2922 VEFF-1982  # Anderson Creek Natural Area
    set_key CA-2923 VEFF-1983  # Anne &amp;amp
    set_key CA-2924 VEFF-1579  # Antler Lake Island Natural Area
    set_key CA-2925 VEFF-1984  # Athabasca Dunes Ecological Reserve
    set_key CA-2927 VEFF-1581  # Aurora Natural Area
    set_key CA-2929 VEFF-1584  # Battle Lake Natural Area
    set_key CA-2930 VEFF-1585  # Bear Lake Natural Area
    set_key CA-2931 VEFF-1586  # Bearberry Prairie Natural Area
    set_key CA-2932 VEFF-1588  # Birch River Wildland Provincial Park
    set_key CA-2933 VEFF-1986  # Beaverhill Lake Heritage Rangeland
    set_key CA-2934 VEFF-1987  # Beaverhill Natural Area
    set_key CA-2935 VEFF-1988  # Beehive Natural Area
    set_key CA-2936 VEFF-1989  # Bentz Lake Natural Area
    set_key CA-2941 VEFF-1990  # Bigoray Natural Area
    set_key CA-2942 VEFF-1991  # Bilby Natural Area
    set_key CA-2943 VEFF-1992  # Black Creek Heritage Rangeland
    set_key CA-2947 VEFF-1589  # Bluerock Wildland Provincial Park
    set_key CA-2948 VEFF-1590  # Bob Creek Wildland Provincial Park
    set_key CA-2950 VEFF-4253  # Bow Valley Wildland Provincial Park
    set_key CA-2951 VEFF-1591  # Brazeau Canyon Wildland Provincial Park
    set_key CA-2954 VEFF-1993  # Bridge Lake Natural Area
    set_key CA-2958 VEFF-4462  # Buck Lake Provincial Recreation Area
    set_key CA-2963 VEFF-1994  # Burtonsville Island Natural Area
    set_key CA-2964 VEFF-1995  # Butcher Creek Natural Area
    set_key CA-2965 VEFF-1592  # Caribou Mountains Wildland Provincial Park
    set_key CA-2966 VEFF-1996  # Caribou River Natural Area
    set_key CA-2971 VEFF-1997  # Castle Provincial Park
    set_key CA-2972 VEFF-1998  # Castle Wildland Provincial Park
    set_key CA-2974 VEFF-2652  # Cataract Creek Provincial Recreation Area
    set_key CA-2975 VEFF-4254  # Centre of Alberta Natural Area
    set_key CA-2976 VEFF-4767  # Chain Lakes Provincial Recreation Area
    set_key CA-2978 VEFF-1999  # Chedderville Natural Area
    set_key CA-2979 VEFF-2000  # Child Lake Meadows Natural Area
    set_key CA-2981 VEFF-1594  # Chinchaga Wildland Provincial Park
    set_key CA-2984 VEFF-2001  # Clear Lake Natural Area
    set_key CA-2985 VEFF-2002  # Clearwater Ricinus Natural Area
    set_key CA-2988 VEFF-2657  # Kazan Wildland Provincial Area
    set_key CA-2989 VEFF-2653  # Cooking Lake-Blackfoot Provincial Recreation Area
    set_key CA-2990 VEFF-2003  # Coyote Lake Natural Area
    set_key CA-2992 VEFF-3739  # Ghost Reservoir Provincial Recreation Area
    set_key CA-2993 VEFF-2004  # Crippsdale Natural Area
    set_key CA-2994 VEFF-4255  # Crow Lake Ecological Reserve
    set_key CA-2998 VEFF-4464  # Dillon River Wildland Provincial Park
    set_key CA-2999 VEFF-4465  # Don Getty Wildland Provincial Park
    set_key CA-3001 VEFF-2005  # Dunvegan West Wildland Provincial Park
    set_key CA-3002 VEFF-2006  # Dussault Lake Natural Area
    set_key CA-3003 VEFF-2007  # Easyford Natural Area
    set_key CA-3004 VEFF-2008  # Easyford Creek Natural Area
    set_key CA-3005 VEFF-2009  # Edgar T. Jones Natural Area
    set_key CA-3010 VEFF-1596  # Elbow-Sheep Wildland Provincial Park
    set_key CA-3014 VEFF-4256  # Emerson Creek Natural Area
    set_key CA-3020 VEFF-1597  # Fidler-Greywillow Wildland Provincial Park
    set_key CA-3021 VEFF-1599  # Fort Assiniboine Sandhills Wildland Provincial Park
    set_key CA-3022 VEFF-4257  # Gadsby Lake Natural Area
    set_key CA-3023 VEFF-4258  # Genesee Natural Area
    set_key CA-3024 VEFF-4259  # George Lake Natural Area
    set_key CA-3025 VEFF-4260  # Ghost River
    set_key CA-3026 VEFF-1601  # Gipsy Lake Wildland Provincial Park
    set_key CA-3028 VEFF-4261  # Goose Mountain Ecological Reserve
    set_key CA-3029 VEFF-1602  # Grand Rapids Wildland Provincial Park
    set_key CA-3030 VEFF-2010  # Grizzly Ridge Wildland Provincial Park
    set_key CA-3031 VEFF-2011  # Halfmoon Lake Natural Area
    set_key CA-3032 VEFF-2012  # Halfway Lake Natural Area
    set_key CA-3033 VEFF-4262  # Hand Hills Ecological Reserve
    set_key CA-3034 VEFF-4466  # Harper Creek Natural Area
    set_key CA-3035 VEFF-2013  # Hastings Lake Islands Natural Area
    set_key CA-3037 VEFF-2014  # Hay-Zama Lakes Wildland Provincial Park
    set_key CA-3039 VEFF-4467  # High Rock Wildland Provincial Park
    set_key CA-3040 VEFF-4263  # Highway Natural Area
    set_key CA-3042 VEFF-2015  # Holmes Crossing Sandhills Ecological Reserve
    set_key CA-3043 VEFF-4264  # Hondo Natural Area
    set_key CA-3045 VEFF-2016  # Hubert Lake Wildland Provincial Park
    set_key CA-3046 VEFF-2656  # Inglewood Migratory Bird Sanctuary
    set_key CA-3047 VEFF-4265  # Innisfail Natural Area
    set_key CA-3048 VEFF-2017  # Isle Lake Natural Area
    set_key CA-3049 VEFF-4266  # J.J. Collett Natural Area
    set_key CA-3050 VEFF-4267  # Kakina Lake Natural Area
    set_key CA-3052 VEFF-2018  # Kakwa Wildland Provincial Park
    set_key CA-3054 VEFF-2019  # Kennedy Coulee Ecological Reserve
    set_key CA-3056 VEFF-4268  # Kleskun Hill Natural Area
    set_key CA-3057 VEFF-4269  # Kootenay Plains Ecological Reserve
    set_key CA-3058 VEFF-2658  # La Biche River Wildland Provincial Park
    set_key CA-3061 VEFF-4271  # Lac La Nonne Natural Area
    set_key CA-3062 VEFF-2021  # Lakeland Provincial Recreation Area
    set_key CA-3063 VEFF-2659  # Lesser Slave Lake Wildland Provincial Park
    set_key CA-3064 VEFF-2022  # Lily Lake Natural Area
    set_key CA-3066 VEFF-4470  # Livingstone Range Wildland Provincial Park
    set_key CA-3067 VEFF-2023  # Lloyd Creek Natural Area
    set_key CA-3070 VEFF-2024  # Marguerite River Wildland Provincial Park
    set_key CA-3072 VEFF-4272  # Marshybank Ecological Reserve
    set_key CA-3074 VEFF-2025  # Matthews Crossing Natural Area
    set_key CA-3078 VEFF-2027  # Milk River Natural Area
    set_key CA-3079 VEFF-4273  # Mill Island Natural Area
    set_key CA-3080 VEFF-2028  # Modeste Creek Natural Area
    set_key CA-3081 VEFF-2029  # Modeste Saskatchewan Natural Area
    set_key CA-3082 VEFF-4274  # Mount Butte Natural Area
    set_key CA-3084 VEFF-4275  # Musreau Lake Provincial Recreation Area
    set_key CA-3085 VEFF-4276  # Mystery Lake Natural Area
    set_key CA-3086 VEFF-4277  # Newton Lake Natural Area
    set_key CA-3087 VEFF-4278  # Noel Lake Natural Area
    set_key CA-3088 VEFF-2030  # North Cooking Lake Natural Area
    set_key CA-3089 VEFF-2661  # Nose Hill Park Natural Area
    set_key CA-3093 VEFF-2031  # Onefour Heritage Rangeland
    set_key CA-3097 VEFF-2032  # Otter-Orloff Lakes Wildland Provincial Park
    set_key CA-3098 VEFF-2662  # Outpost Wetlands Natural Area
    set_key CA-3099 VEFF-4279  # Paddle River Natural Area
    set_key CA-3102 VEFF-2033  # Parkland Natural Area
    set_key CA-3103 VEFF-2034  # Peace River Wildland Provincial Park
    set_key CA-3105 VEFF-4280  # Pembina River Moon Lake Natural Area
    set_key CA-3106 VEFF-4281  # Pembina River Natural Area
    set_key CA-3107 VEFF-2663  # Pinto Creek Canyon Natural Area
    set_key CA-3108 VEFF-4282  # Plateau Mountain Ecological Reserve
    set_key CA-3109 VEFF-2664  # Police Point Natural Area
    set_key CA-3111 VEFF-2665  # Prairie Coulees Natural Area
    set_key CA-3112 VEFF-4283  # Prefontaine Brock Lakes Natural Area
    set_key CA-3113 VEFF-2654  # Gaetz Lakes Sanctuary
    set_key CA-3114 VEFF-4284  # Red Rock Coulee Natural Area
    set_key CA-3115 VEFF-4285  # Redwater River Natural Area
    set_key CA-3116 VEFF-2666  # Richardson Lake Migratory Bird Sanctuary
    set_key CA-3118 VEFF-2667  # Richardson Wildland Provincial Park
    set_key CA-3119 VEFF-2036  # Rock Lake - Solomon Creek Wildland Provincial Park
    set_key CA-3120 VEFF-2037  # Rocky Rapids Natural Area
    set_key CA-3121 VEFF-4286  # Roselea Natural Area
    set_key CA-3123 VEFF-4287  # Rumsey Ecological Reserve
    set_key CA-3124 VEFF-2668  # Sand Lake Natural Area
    set_key CA-3125 VEFF-2669  # Saskatoon Lake Migratory Bird Sanctuary
    set_key CA-3126 VEFF-4288  # Saulteaux Natural Area
    set_key CA-3128 VEFF-4289  # Sheep Creek Natural Area
    set_key CA-3130 VEFF-4292  # Silver Valley Ecological Reserve
    set_key CA-3131 VEFF-4293  # Snakes Head Natural Area
    set_key CA-3132 VEFF-2670  # Spruce Island Lake Natural Area
    set_key CA-3133 VEFF-2038  # St. Francis Natural Area
    set_key CA-3134 VEFF-2039  # Stony Mountain Wildland Provincial Park
    set_key CA-3136 VEFF-3114  # Fort Vermilion National Historic Site
    set_key CA-3139 VEFF-4294  # Sulphur Gates Provincial Recreation Area
    set_key CA-3140 VEFF-4295  # Sundance Natural Area
    set_key CA-3142 VEFF-4296  # Sundre North Natural Area
    set_key CA-3143 VEFF-4297  # Sundre Red Deer Natural Area
    set_key CA-3144 VEFF-4298  # Sylvan Lake Natural Area
    set_key CA-3147 VEFF-2040  # Taylor Lake Natural Area
    set_key CA-3149 VEFF-2041  # Threepoint Creek Natural Area
    set_key CA-3150 VEFF-2042  # Town Creek Natural Area
    set_key CA-3151 VEFF-2043  # Twin River Heritage Rangeland
    set_key CA-3152 VEFF-2044  # Upper Mann Lake Natural Area
    set_key CA-3154 VEFF-3743  # Wagner Natural Area
    set_key CA-3155 VEFF-4299  # Wainwright Dunes Ecological Reserve
    set_key CA-3157 VEFF-4301  # Waterton - Glacier International Peace Park
    set_key CA-3159 VEFF-2045  # West Castle Wetlands Ecological Reserve
    set_key CA-3160 VEFF-2046  # White Earth Valley Natural Area
    set_key CA-3161 VEFF-4302  # White Goat Natural Area
    set_key CA-3162 VEFF-4303  # Whitecourt Mountain Natural Area
    set_key CA-3163 VEFF-2047  # Whitehorse Wildland Provincial Park
    set_key CA-3164 VEFF-4471  # Whitemud Falls Ecological Reserve
    set_key CA-3165 VEFF-2048  # Whitemud Falls Wildland Provincial Park
    set_key CA-3166 VEFF-2049  # Wildhay Glacial Cascades Natural Area
    set_key CA-3167 VEFF-2050  # Willmore Wilderness Park Wilderness Park
    set_key CA-3168 VEFF-2051  # Winagami Wildland Provincial Park
    set_key CA-3180 VEFF-4473  # Allco Park
    set_key CA-3188 VEFF-1221  # Brooks Peninsula Provincial Park (aka Muqqiwn Provincial Park)
    set_key CA-3189 VEFF-2053  # Arctic Pacific Lakes Provincial Park
    set_key CA-3190 VEFF-2054  # Arrow Lakes (Shelter Bay) Provincial Park
    set_key CA-3195 VEFF-2055  # Babine River Corridor Provincial Park
    set_key CA-3199 VEFF-3128  # Barkerville Historic Town and Park
    set_key CA-3203 VEFF-2056  # Bearhole Lake Provincial Park
    set_key CA-3205 VEFF-1222  # Carmanah Walbran Provincial Park
    set_key CA-3206 VEFF-2057  # Beatton River Provincial Park
    set_key CA-3207 VEFF-1224  # Clayoquot Arm Provincial Park
    set_key CA-3208 VEFF-1227  # E.C. Manning Provincial Park
    set_key CA-3209 VEFF-4477  # Beaver Point Provincial Park
    set_key CA-3212 VEFF-1228  # East Sooke Regional Park
    set_key CA-3217 VEFF-1233  # Goat Range Provincial Park
    set_key CA-3219 VEFF-1613  # Bert Brink Wildlife Management Area
    set_key CA-3220 VEFF-1234  # Golden Ears Provincial Park
    set_key CA-3225 VEFF-1235  # Gowlland Tod Provincial Park
    set_key CA-3228 VEFF-1236  # Lac du Bois Grasslands Protected Area
    set_key CA-3229 VEFF-1238  # Matheson Lake Regional Park
    set_key CA-3231 VEFF-1243  # Pinecone Burke Provincial Park
    set_key CA-3234 VEFF-2058  # Blue Earth Lake Provincial Park
    set_key CA-3237 VEFF-1244  # Rolley Lake Provincial Park
    set_key CA-3239 VEFF-1248  # Sooke Potholes Provincial Park
    set_key CA-3242 VEFF-1614  # Boothman's Oxbow Provincial Park
    set_key CA-3245 VEFF-4480  # Boundary Bay Wildlife Management Area
    set_key CA-3248 VEFF-2672  # Bowser Ecological Reserve
    set_key CA-3250 VEFF-2059  # Boyle Point Provincial Park
    set_key CA-3252 VEFF-1251  # Swiws (Haynes Point) Provincial Park
    set_key CA-3253 VEFF-1220  # Brandywine Falls Provincial Park
    set_key CA-3255 VEFF-1615  # Bridal Veil Falls Provincial Park
    set_key CA-3258 VEFF-4482  # Bright Angel Provincial Park
    set_key CA-3265 VEFF-2060  # Buccaneer Bay Provincial Park
    set_key CA-3272 VEFF-4483  # Buntzen Lake Recreation Area
    set_key CA-3275 VEFF-2061  # Burgoyne Bay Provincial Park
    set_key CA-3277 VEFF-4484  # Burnaby Lake Regional Park
    set_key CA-3278 VEFF-4485  # Burnaby Mountain Conservation Area
    set_key CA-3282 VEFF-4491  # Delta Nature Reserve
    set_key CA-3283 VEFF-1618  # Burns Lake Provincial Park
    set_key CA-3288 VEFF-2062  # Butler Ridge Provincial Park
    set_key CA-3290 VEFF-2063  # Caligata Lake Provincial Park
    set_key CA-3291 VEFF-2064  # Call Lake Provincial Park
    set_key CA-3293 VEFF-1619  # Callaghan Lake Provincial Park
    set_key CA-3296 VEFF-2065  # Canim Beach Provincial Park
    set_key CA-3299 VEFF-2066  # Cariboo Nature Park
    set_key CA-3305 VEFF-2067  # Castle Rock Hoodoos Provincial Park
    set_key CA-3307 VEFF-1621  # Cedar Creek Park Conservation Area
    set_key CA-3314 VEFF-2068  # Cedar Point Provincial Park
    set_key CA-3319 VEFF-2069  # Charlie Lake Provincial Park
    set_key CA-3321 VEFF-2070  # Chasm Provincial Park
    set_key CA-3323 VEFF-1623  # Chemainus River Provincial Park
    set_key CA-3327 VEFF-1223  # Chilliwack Lake Provincial Park
    set_key CA-3328 VEFF-1626  # Chilliwack River Provincial Park
    set_key CA-3329 VEFF-1625  # Chilliwack River Ecological Reserve
    set_key CA-3332 VEFF-1627  # Christina Lake Provincial Park
    set_key CA-3333 VEFF-2071  # Chu Chua Cottonwood Provincial Park
    set_key CA-3338 VEFF-2072  # Cinnemousun Narrows Provincial Park
    set_key CA-3339 VEFF-1628  # Citadel Heights Park Protected Area
    set_key CA-3341 VEFF-2673  # Claud Elliott Creek Ecological Reserve
    set_key CA-3342 VEFF-1629  # Claud Elliot Lake Provincial Park
    set_key CA-3344 VEFF-1630  # Clayoquot Plateau Provincial Park
    set_key CA-3347 VEFF-2073  # Clendinning Provincial Park
    set_key CA-3350 VEFF-2674  # Cluxewe Wildlife Management Area
    set_key CA-3355 VEFF-2074  # Cody Caves Provincial Park
    set_key CA-3356 VEFF-2075  # Coldwater River Provincial Park
    set_key CA-3357 VEFF-1225  # Collinson Point Provincial Park
    set_key CA-3359 VEFF-1631  # Colony Farm Regional Park
    set_key CA-3360 VEFF-2076  # Columbia Lake Provincial Park
    set_key CA-3363 VEFF-2675  # Comox Lake Bluffs Ecological Reserve
    set_key CA-3364 VEFF-2077  # Conkle Lake Provincial Park
    set_key CA-3367 VEFF-2078  # Coquihalla Canyon Provincial Park
    set_key CA-3372 VEFF-2079  # Cornwall Hills Provincial Park
    set_key CA-3374 VEFF-2080  # Cottonwood River Provincial Park
    set_key CA-3379 VEFF-1632  # Cowichan River Provincial Park
    set_key CA-3390 VEFF-4481  # Brae Island Regional Park
    set_key CA-3401 VEFF-2081  # Darke Lake Provincial Park
    set_key CA-3402 VEFF-1633  # Davis Lake Provincial Park
    set_key CA-3410 VEFF-2082  # Denman Island Provincial Park
    set_key CA-3412 VEFF-1634  # Derby Reach Regional Park
    set_key CA-3415 VEFF-1635  # Devonian Harbour Park Protected Area
    set_key CA-3418 VEFF-2083  # Diana Lake Provincial Park
    set_key CA-3419 VEFF-1226  # Dionisio Point Provincial Park
    set_key CA-3420 VEFF-4492  # Discovery Island Marine Provincial Park
    set_key CA-3428 VEFF-2084  # Downing Provincial Park
    set_key CA-3434 VEFF-2085  # Drumbeg Provincial Park
    set_key CA-3438 VEFF-4493  # Duke Of Edinburgh (Pine/Storm/Tree Islets) Ecological Reserve
    set_key CA-3445 VEFF-4499  # Glen Valley Regional Park Two-bit Bar
    set_key CA-3454 VEFF-1620  # Campbell Valley Regional Park
    set_key CA-3461 VEFF-2086  # Edge Hills Provincial Park
    set_key CA-3463 VEFF-2087  # Elephant Hill Provincial Park
    set_key CA-3465 VEFF-1229  # Elk Falls Provincial Park
    set_key CA-3468 VEFF-1637  # Elko Provincial Park
    set_key CA-3472 VEFF-1230  # Ellison Provincial Park
    set_key CA-3473 VEFF-2088  # Emar Lakes Provincial Park
    set_key CA-3475 VEFF-1638  # Emory Creek Provincial Park
    set_key CA-3477 VEFF-2089  # Enderby Cliffs Provincial Park
    set_key CA-3478 VEFF-2090  # Eneas Lakes Provincial Park
    set_key CA-3481 VEFF-1639  # Englishman River Falls Provincial Park
    set_key CA-3482 VEFF-1640  # Epper Passage Provincial Park
    set_key CA-3485 VEFF-1641  # Erie Creek Provincial Park
    set_key CA-3487 VEFF-3148  # Esquimalt Lagoon Migratory Bird Sanctuary
    set_key CA-3494 VEFF-1642  # Eves Provincial Park
    set_key CA-3499 VEFF-2091  # F.H. Barber Provincial Park
    set_key CA-3501 VEFF-2092  # Fillongley Provincial Park
    set_key CA-3504 VEFF-1231  # Fintry Provincial Park
    set_key CA-3507 VEFF-2093  # Flat Lake Provincial Park
    set_key CA-3510 VEFF-2094  # Flores Island Provincial Park
    set_key CA-3516 VEFF-2095  # Fort George Canyon Provincial Park
    set_key CA-3520 VEFF-1650  # Fossli Provincial Park
    set_key CA-3523 VEFF-2096  # Francis Point Provincial Park
    set_key CA-3527 VEFF-1651  # Fraser River Ecological Reserve
    set_key CA-3528 VEFF-1652  # Fraser View Park
    set_key CA-3529 VEFF-2097  # Fred Antoine Provincial Park
    set_key CA-3531 VEFF-1653  # French Beach Provincial Park
    set_key CA-3533 VEFF-2098  # Gabriola Sands Provincial Park
    set_key CA-3534 VEFF-4497  # Galiano Island Ecological Reserve
    set_key CA-3544 VEFF-1232  # Gilpin Grasslands Provincial Park
    set_key CA-3550 VEFF-2099  # Gladstone Provincial Park
    set_key CA-3556 VEFF-1655  # Gold Muchalat Provincial Park
    set_key CA-3558 VEFF-2100  # Goldpan Provincial Park
    set_key CA-3561 VEFF-1656  # Gordon Bay Provincial Park
    set_key CA-3562 VEFF-3175  # North Pacific Cannery National Historical Site
    set_key CA-3563 VEFF-2101  # Graham-Laurier Provincial Park
    set_key CA-3564 VEFF-2102  # Granby Provincial Park
    set_key CA-3567 VEFF-2103  # Great Glacier Provincial Park
    set_key CA-3571 VEFF-2676  # Green Mountain Wildlife Management Area
    set_key CA-3573 VEFF-2104  # Grohman Narrows Provincial Park
    set_key CA-3575 VEFF-2105  # Gwillim Lake Provincial Park
    set_key CA-3576 VEFF-2106  # Gwyneth Lake Provincial Park
    set_key CA-3580 VEFF-1659  # Haley Lake Ecological Reserve
    set_key CA-3581 VEFF-2107  # Halkett Bay Marine Provincial Park
    set_key CA-3597 VEFF-2108  # Helliwell Provincial Park
    set_key CA-3598 VEFF-1661  # Hemer Provincial Park
    set_key CA-3599 VEFF-2109  # Herald Provincial Park
    set_key CA-3600 VEFF-1662  # Hesquiat Lake Provincial Park
    set_key CA-3602 VEFF-2110  # High Lakes Basin Provincial Park
    set_key CA-3604 VEFF-1663  # Hitchie Creek Provincial Park
    set_key CA-3610 VEFF-2677  # Honeymoon Bay Ecological Reserve
    set_key CA-3624 VEFF-1664  # Inkaneep Provincial Park
    set_key CA-3628 VEFF-2111  # Itcha Ilgachuz Provincial Park
    set_key CA-3632 VEFF-1667  # James Chabot Provincial Park
    set_key CA-3638 VEFF-1668  # Jewel Lake Provincial Park
    set_key CA-3641 VEFF-1669  # John Dean Provincial Park
    set_key CA-3643 VEFF-1671  # Johnstone Creek Provincial Park
    set_key CA-3644 VEFF-1672  # Juan de Fuca Provincial Park
    set_key CA-3647 VEFF-2112  # Juniper Beach Provincial Park
    set_key CA-3660 VEFF-1674  # Kanaka Creek Regional Park
    set_key CA-3661 VEFF-1675  # Katherine Tye (Vedder Crossing) Ecological Reserve
    set_key CA-3662 VEFF-2113  # Kekuli Bay Provincial Park
    set_key CA-3664 VEFF-2678  # Kennedy Lake Provincial Park
    set_key CA-3665 VEFF-2679  # Kennedy River Bog Provincial Park
    set_key CA-3676 VEFF-2114  # Kikomun Creek Provincial Park
    set_key CA-3679 VEFF-1678  # Kilby Provincial Park
    set_key CA-3680 VEFF-1679  # Kin Beach Provincial Park
    set_key CA-3682 VEFF-1680  # King George VI Provincial Park
    set_key CA-3685 VEFF-2115  # Kingfisher Creek Provincial Park
    set_key CA-3686 VEFF-2116  # Kiskatinaw Provincial Park
    set_key CA-3687 VEFF-2117  # Kiskatinaw River Provincial Park
    set_key CA-3692 VEFF-2118  # Kitsumkalum Provincial Park
    set_key CA-3694 VEFF-1683  # Kitty Coleman Beach Provincial Park
    set_key CA-3698 VEFF-3164  # Kleanza Creek Provincial Park
    set_key CA-3704 VEFF-2119  # Kluskoil Lake Provincial Park
    set_key CA-3707 VEFF-2120  # Kokanee Glacier Provincial Park
    set_key CA-3708 VEFF-1684  # Koksilah River Provincial Park
    set_key CA-3709 VEFF-1686  # Kootenay Lake Provincial Park
    set_key CA-3719 VEFF-2121  # Lac La Hache Provincial Park
    set_key CA-3727 VEFF-1687  # Lawn Point Provincial Park
    set_key CA-3732 VEFF-2680  # Lazo Marsh - North East Comox Management Wildlife Management Area
    set_key CA-3739 VEFF-1688  # Lighthouse Park Protected Area
    set_key CA-3744 VEFF-1689  # Little Qualicum Falls Provincial Park
    set_key CA-3745 VEFF-1690  # Liumchen Ecological Reserve
    set_key CA-3747 VEFF-2122  # Lockhart Beach Provincial Park
    set_key CA-3748 VEFF-2123  # Lockhart Creek Provincial Park
    set_key CA-3753 VEFF-1237  # Loveland Bay Provincial Park
    set_key CA-3755 VEFF-1691  # Lower Nimpkish River Provincial Park
    set_key CA-3758 VEFF-1692  # Lower Tsitika River Provincial Park
    set_key CA-3761 VEFF-2124  # Mabel Lake Provincial Park
    set_key CA-3765 VEFF-1693  # MacMillan Provincial Park
    set_key CA-3768 VEFF-2125  # Main Lake Provincial Park
    set_key CA-3769 VEFF-2126  # Malaspina Provincial Park
    set_key CA-3782 VEFF-2127  # Mara Meadows Provincial Park
    set_key CA-3783 VEFF-2128  # Marble Canyon Provincial Park
    set_key CA-3784 VEFF-2129  # Marble Range Provincial Park
    set_key CA-3785 VEFF-2130  # Marble River Provincial Park
    set_key CA-3793 VEFF-1694  # McConnell Lake Provincial Park
    set_key CA-3794 VEFF-1695  # McDonald Creek Provincial Park
    set_key CA-3798 VEFF-2681  # Megin River Ecological Reserve
    set_key CA-3799 VEFF-2131  # Mehatl Creek Provincial Park
    set_key CA-3802 VEFF-2132  # Memory Island Provincial Park
    set_key CA-3807 VEFF-1699  # Miracle Beach Provincial Park
    set_key CA-3813 VEFF-2133  # Momich Lakes Provincial Park
    set_key CA-3818 VEFF-4512  # Montague Harbour Marine Park
    set_key CA-3823 VEFF-1701  # Morden Colliery Historic Provincial Park
    set_key CA-3827 VEFF-1702  # Morrissey Provincial Park
    set_key CA-3828 VEFF-1703  # Morton Lake Provincial Park
    set_key CA-3829 VEFF-1704  # Mount Assiniboine Provincial Park
    set_key CA-3830 VEFF-2134  # Mount Blanchet Provincial Park
    set_key CA-3831 VEFF-2682  # Mount Derby Ecological Reserve
    set_key CA-3833 VEFF-2683  # Mount Elliot Ecological Reserve
    set_key CA-3834 VEFF-1705  # Mount Elphinstone Provincial Park
    set_key CA-3835 VEFF-2135  # Mount Erskine Provincial Park
    set_key CA-3837 VEFF-2136  # Mount Geoffrey Escarpment Provincial Park
    set_key CA-3839 VEFF-2137  # Mount Griffin Provincial Park
    set_key CA-3840 VEFF-4514  # Mount Maxwell Ecological Reserve
    set_key CA-3841 VEFF-2138  # Mount Maxwell Provincial Park
    set_key CA-3844 VEFF-2139  # Mount Richardson Provincial Park
    set_key CA-3847 VEFF-1239  # Mount Robson Provincial Park
    set_key CA-3849 VEFF-2140  # Mount Savona Provincial Park
    set_key CA-3850 VEFF-2141  # Mount Seymour Provincial Park
    set_key CA-3853 VEFF-4515  # Mount Tuam Ecological Reserve
    set_key CA-3861 VEFF-1706  # Murrin Provincial Park
    set_key CA-3863 VEFF-2142  # Myra-Bellevue Provincial Park
    set_key CA-3878 VEFF-3173  # Nancy Greene Provincial Park
    set_key CA-3881 VEFF-2143  # Nation Lakes Provincial Park
    set_key CA-3892 VEFF-2144  # Nickel Plate Provincial Park
    set_key CA-3893 VEFF-2145  # Nicolum River Provincial Park
    set_key CA-3895 VEFF-2684  # Nimpkish River Ecological Reserve
    set_key CA-3901 VEFF-2146  # Niskonlith Lake Provincial Park
    set_key CA-3902 VEFF-2685  # Nitinat Lake Ecological Reserve
    set_key CA-3903 VEFF-1708  # Nitinat River Provincial Park
    set_key CA-3906 VEFF-1709  # Norbury Lake Provincial Park
    set_key CA-3915 VEFF-1710  # Nuchatlitz Provincial Park
    set_key CA-3916 VEFF-2147  # Nunsti Provincial Park
    set_key CA-3920 VEFF-1240  # Okanagan Falls Provincial Park
    set_key CA-3921 VEFF-1241  # Okanagan Lake Provincial Park
    set_key CA-3922 VEFF-1242  # Okanagan Mountain Provincial Park
    set_key CA-3923 VEFF-2148  # Okeover Arm Provincial Park
    set_key CA-3926 VEFF-2150  # Omineca Provincial Park
    set_key CA-3927 VEFF-2149  # Omineca Protected Area
    set_key CA-3928 VEFF-2151  # One Island Lake Provincial Park
    set_key CA-3930 VEFF-2152  # Oregon Jack Provincial Park
    set_key CA-3932 VEFF-1711  # Otter Lake Provincial Park
    set_key CA-3939 VEFF-4517  # Pacific Spirit Regional Park
    set_key CA-3940 VEFF-2153  # Painted Bluffs Provincial Park
    set_key CA-3944 VEFF-2686  # Parksville-Qualicum Beach Wildlife Management Area
    set_key CA-3947 VEFF-2154  # Paul Lake Provincial Park
    set_key CA-3948 VEFF-2155  # Peace Arch Provincial Park
    set_key CA-3949 VEFF-2156  # Peace River Corridor Provincial Park
    set_key CA-3951 VEFF-2157  # Pennask Creek Provincial Park
    set_key CA-3952 VEFF-2158  # Pennask Lake Provincial Park
    set_key CA-3955 VEFF-1713  # Petroglyph Provincial Park
    set_key CA-3959 VEFF-2159  # Pine Le Moray Provincial Park
    set_key CA-3962 VEFF-2160  # Pinnacles Provincial Park
    set_key CA-3965 VEFF-1714  # Pitt-Addington Marsh
    set_key CA-3966 VEFF-4519  # Pitt Meadows Athletic Park Recreation Site
    set_key CA-3974 VEFF-2161  # Porcupine Meadows Provincial Park
    set_key CA-3981 VEFF-2162  # Premier Lake Provincial Park
    set_key CA-3990 VEFF-2163  # Pukeashun Provincial Park
    set_key CA-3993 VEFF-2164  # Purcell Wilderness Conservancy
    set_key CA-3999 VEFF-1716  # Quatsino Provincial Park
    set_key CA-4012 VEFF-1717  # Rathtrevor Beach Provincial Park
    set_key CA-4013 VEFF-2165  # Read Island Provincial Park
    set_key CA-4015 VEFF-4523  # Rebecca Spit Marine Park
    set_key CA-4025 VEFF-1718  # Robert Burnaby Park
    set_key CA-4026 VEFF-4524  # Roberts Bank Wildlife Management Area
    set_key CA-4027 VEFF-4525  # Roberts Creek Provincial Park
    set_key CA-4028 VEFF-1720  # Roberts Memorial Provincial Park
    set_key CA-4030 VEFF-2166  # Roche Lake Provincial Park
    set_key CA-4034 VEFF-2195  # Tsutswecw (Roderick Haig-Brown) Provincial Park
    set_key CA-4039 VEFF-2167  # Rosebery Provincial Park
    set_key CA-4040 VEFF-1722  # Rosewall Creek Provincial Park
    set_key CA-4041 VEFF-1723  # Ross Lake Ecological Reserve
    set_key CA-4042 VEFF-2168  # Ross Lake Provincial Park
    set_key CA-4044 VEFF-2169  # Ruckle Provincial Park
    set_key CA-4046 VEFF-2170  # Ruth Lake Provincial Park
    set_key CA-4047 VEFF-2171  # Ryan Provincial Park
    set_key CA-4049 VEFF-2173  # Saltery Bay Provincial Park
    set_key CA-4050 VEFF-1725  # San Juan Ridge Ecological Reserve
    set_key CA-4051 VEFF-1726  # San Juan River Estuary
    set_key CA-4054 VEFF-2174  # Sandwell Provincial Park
    set_key CA-4061 VEFF-2175  # Sasquatch Provincial Park
    set_key CA-4063 VEFF-1728  # Schoen Lake Provincial Park
    set_key CA-4069 VEFF-4526  # Serpentine Wildlife Management Area
    set_key CA-4071 VEFF-1729  # Settlers Park Protected Area
    set_key CA-4076 VEFF-1245  # Shannon Falls Provincial Park
    set_key CA-4080 VEFF-2176  # Shuswap Lake Marine Provincial Park
    set_key CA-4081 VEFF-1246  # Shuswap Lake Marine Provincial Park
    set_key CA-4088 VEFF-2177  # Silver Lake Provincial Park
    set_key CA-4089 VEFF-2178  # Silver Star Provincial Park
    set_key CA-4094 VEFF-1730  # Skagit River Cottonwoods Ecological Reserve
    set_key CA-4095 VEFF-1731  # Skagit River Forest Ecological Reserve
    set_key CA-4097 VEFF-2179  # Skaha Bluffs Provincial Park
    set_key CA-4102 VEFF-1247  # Skookumchuck Narrows Provincial Park
    set_key CA-4111 VEFF-2180  # Smelt Bay Provincial Park
    set_key CA-4119 VEFF-1733  # Sooke Mountain Provincial Park
    set_key CA-4120 VEFF-4527  # South Arm Marshes Wildlife Management Area
    set_key CA-4121 VEFF-2181  # South Chilcotin Mountains Provincial Park
    set_key CA-4123 VEFF-1249  # South Okanagan Grasslands Protected Area
    set_key CA-4124 VEFF-2182  # South Texada Island Provincial Park
    set_key CA-4130 VEFF-1734  # Spectacle Lake Provincial Park
    set_key CA-4131 VEFF-1735  # Spider Lake Provincial Park
    set_key CA-4132 VEFF-2183  # Spipiyus Provincial Park
    set_key CA-4133 VEFF-1736  # Sproat Lake Provincial Park
    set_key CA-4135 VEFF-2172  # St. Mary's Alpine Provincial Park
    set_key CA-4140 VEFF-1737  # Stamp River Provincial Park
    set_key CA-4142 VEFF-1250  # Stawamus Chief Provincial Park
    set_key CA-4144 VEFF-2184  # Steelhead Provincial Park
    set_key CA-4145 VEFF-2185  # Stein Valley Nlaka'pamux Heritage Park
    set_key CA-4150 VEFF-1740  # Stoyoma Creek Ecological Reserve
    set_key CA-4151 VEFF-1741  # Strathcona Provincial Park
    set_key CA-4154 VEFF-2186  # Stuart River Provincial Park
    set_key CA-4160 VEFF-1742  # Sulphur Passage Provincial Park
    set_key CA-4161 VEFF-2187  # Summit Lake Provincial Park
    set_key CA-4164 VEFF-2188  # Surge Narrows Provincial Park
    set_key CA-4165 VEFF-1743  # Surrey Bend Regional Park
    set_key CA-4166 VEFF-1744  # Surrey Lake Park
    set_key CA-4173 VEFF-4502  # Green Timbers Urban Forest Park
    set_key CA-4177 VEFF-2687  # Tahsish River Ecological Reserve
    set_key CA-4181 VEFF-1746  # Tantalus Provincial Park
    set_key CA-4185 VEFF-2189  # Taweel Provincial Park
    set_key CA-4186 VEFF-1747  # Taylor Arm Provincial Park
    set_key CA-4188 VEFF-2190  # Teakerne Arm Provincial Park
    set_key CA-4189 VEFF-1748  # Telegraph Trail Park Protected Area
    set_key CA-4192 VEFF-2191  # Tetrahedron Provincial Park
    set_key CA-4197 VEFF-2192  # Three Sisters Lake Provincial Park
    set_key CA-4208 VEFF-2193  # Top of the World Provincial Park
    set_key CA-4219 VEFF-2194  # Tribune Bay Provincial Park
    set_key CA-4227 VEFF-2197  # Tunkwa Provincial Park
    set_key CA-4233 VEFF-2198  # Tweedsmuir South Provincial Park
    set_key CA-4234 VEFF-2199  # Tyhee Lake Provincial Park
    set_key CA-4235 VEFF-4529  # Tynehead Regional Park
    set_key CA-4240 VEFF-2200  # Upper Adams River Provincial Park
    set_key CA-4246 VEFF-2201  # Upper Seymour River Provincial Park
    set_key CA-4249 VEFF-2202  # Upper Violet Creek Provincial Park
    set_key CA-4250 VEFF-2203  # Valhalla Provincial Park
    set_key CA-4252 VEFF-4530  # Vance Creek Ecological Reserve
    set_key CA-4253 VEFF-1252  # Vaseux Lake Provincial Park
    set_key CA-4257 VEFF-2204  # Victor Lake Provincial Park
    set_key CA-4258 VEFF-3773  # Victoria Harbour Migratory Bird Sanctuary
    set_key CA-4263 VEFF-2205  # Wakes Cove Provincial Park
    set_key CA-4265 VEFF-2206  # Walhachin Oxbows Provincial Park
    set_key CA-4266 VEFF-4531  # Wallace Island Marine Park
    set_key CA-4269 VEFF-2207  # Walsh Cove Provincial Park
    set_key CA-4272 VEFF-1753  # Wasa Lake Provincial Park
    set_key CA-4276 VEFF-2208  # Wells Gray Provincial Park
    set_key CA-4278 VEFF-2209  # West Arm Provincial Park
    set_key CA-4281 VEFF-1754  # West Shawnigan Lake Provincial Park
    set_key CA-4284 VEFF-1755  # Weymer Creek Provincial Park
    set_key CA-4287 VEFF-2210  # Whiskers Point Provincial Park
    set_key CA-4291 VEFF-1756  # White Ridge Provincial Park
    set_key CA-4292 VEFF-1757  # White River Provincial Park
    set_key CA-4293 VEFF-1758  # Whiteswan Lake Provincial Park
    set_key CA-4311 VEFF-1760  # Yale Garry Oak Ecological Reserve
    set_key CA-4312 VEFF-2211  # Yard Creek Provincial Park
    set_key CA-4313 VEFF-2688  # Yellow Point Bog Ecological Reserve
    set_key CA-4316 VEFF-1253  # 60th Parallel Territorial Park
    set_key CA-4317 VEFF-2212  # Alexandra Falls Territorial Park
    set_key CA-4318 VEFF-2213  # Anderson River Delta Migratory Bird Sanctuary
    set_key CA-4320 VEFF-2214  # Banks Island Migratory Bird Sanctuary No. 1
    set_key CA-4321 VEFF-2215  # Banks Island Migratory Bird Sanctuary No. 2
    set_key CA-4322 VEFF-2216  # Cameron River Crossing Territorial Park
    set_key CA-4323 VEFF-2217  # Cape Parry Migratory Bird Sanctuary
    set_key CA-4324 VEFF-2220  # Dory Point Territorial Park
    set_key CA-4326 VEFF-2223  # Fort Providence Territorial Park
    set_key CA-4327 VEFF-2226  # Fort Smith Mission Territorial Park
    set_key CA-4328 VEFF-2227  # Gwich'in Territorial Park
    set_key CA-4329 VEFF-1254  # Happy Valley Territorial Park
    set_key CA-4330 VEFF-2229  # Kakisa River Territorial Park
    set_key CA-4331 VEFF-2230  # Kelly Lake Protected Area
    set_key CA-4332 VEFF-2231  # Kendall Island Migratory Bird Sanctuary
    set_key CA-4333 VEFF-2690  # Little Buffalo River Crossing Territorial Park
    set_key CA-4334 VEFF-2691  # Little Buffalo River Falls Territorial Park
    set_key CA-4335 VEFF-1255  # Louise Falls Campground &amp; Day Use Area
    set_key CA-4336 VEFF-2233  # McKinnon Territorial Park
    set_key CA-4337 VEFF-2234  # McNallie Creek Territorial Park
    set_key CA-4338 VEFF-2236  # North Arm Territorial Park
    set_key CA-4339 VEFF-2238  # Pontoon Lake Territorial Park
    set_key CA-4340 VEFF-2692  # Powder Point Territorial Park
    set_key CA-4341 VEFF-2239  # Prosperous Lake Territorial Park Area
    set_key CA-4343 VEFF-2693  # Sambaa Deh Falls Territorial Park
    set_key CA-4348 VEFF-2241  # Yellowknife River Territorial Park
    set_key CA-4349 VEFF-2242  # Adder Lakes Protected Natural Area
    set_key CA-4351 VEFF-4540  # Andersonville Natural Area
    set_key CA-4352 VEFF-4541  # Angle Hill Lake Natural Area
    set_key CA-4353 VEFF-4542  # Ayers Lake Stream Protected Area
    set_key CA-4354 VEFF-4543  # Baker Brook Natural Area
    set_key CA-4355 VEFF-1762  # Bantalor Wildlife Management Area
    set_key CA-4356 VEFF-4544  # Bass River Natural Area
    set_key CA-4357 VEFF-4545  # Becaguimec Stream Natural Area
    set_key CA-4359 VEFF-4546  # Bellefond Natural Area
    set_key CA-4360 VEFF-3780  # Belleville Protected Area
    set_key CA-4361 VEFF-4547  # Bells Brook Natural Area
    set_key CA-4362 VEFF-4548  # Belone Brook Natural Area
    set_key CA-4363 VEFF-2243  # Big Bald Mountain Protected Area
    set_key CA-4364 VEFF-4550  # Big Cedar Brook Natural Area
    set_key CA-4365 VEFF-4551  # Big Falls Natural Area
    set_key CA-4366 VEFF-4552  # Big Meadows Natural Area
    set_key CA-4368 VEFF-3782  # Big Salmon River Protected Area
    set_key CA-4370 VEFF-4555  # Blind Brook Natural Area
    set_key CA-4371 VEFF-4556  # Blind Gully Brook Natural Area
    set_key CA-4372 VEFF-4557  # Blueberry Brook Natural Area
    set_key CA-4373 VEFF-4558  # Boland Brook Natural Area
    set_key CA-4374 VEFF-4559  # Brantville Natural Area
    set_key CA-4375 VEFF-3783  # Brookvale Protected Area
    set_key CA-4377 VEFF-2246  # Burgess Settlement Protected Area
    set_key CA-4378 VEFF-4561  # Burpee Lake Natural Area
    set_key CA-4379 VEFF-4562  # Butte à Morrison Natural Area
    set_key CA-4381 VEFF-4564  # Canaan Bog Natural Area
    set_key CA-4382 VEFF-4565  # Carr Falls Brook Natural Area
    set_key CA-4383 VEFF-3784  # Cat Road Protected Area
    set_key CA-4384 VEFF-3788  # Cowlily Pond Brook
    set_key CA-4385 VEFF-4566  # Dead Creek Natural Area
    set_key CA-4387 VEFF-4568  # Dionne Brook Natural Area
    set_key CA-4388 VEFF-4569  # Dowdall Lake Natural Area
    set_key CA-4389 VEFF-4570  # Downs Gulch Natural Area
    set_key CA-4390 VEFF-4571  # East Cloverdale Natural Area
    set_key CA-4391 VEFF-4572  # Eel River Natural Area
    set_key CA-4392 VEFF-4573  # Eight Mile Brook Natural Area
    set_key CA-4393 VEFF-3213  # Estey Wetlands Protected Area
    set_key CA-4394 VEFF-4574  # Falls Brook Natural Area
    set_key CA-4395 VEFF-4575  # First Eel Lake Natural Area
    set_key CA-4396 VEFF-4576  # Five Mile Brook Natural Area
    set_key CA-4397 VEFF-4577  # Foley Island Natural Area
    set_key CA-4398 VEFF-4578  # Gaspereau Natural Area
    set_key CA-4399 VEFF-4579  # Golden Ridge Natural Area
    set_key CA-4400 VEFF-4580  # Goodfellow Brook Natural Area
    set_key CA-4401 VEFF-3794  # Gooseberry Cove Protected Area
    set_key CA-4402 VEFF-4581  # Gordon Meadow Brook Natural Area
    set_key CA-4403 VEFF-4582  # Gover Mountain Natural Area
    set_key CA-4404 VEFF-2252  # Grand Manan Migratory Bird Sanctuary
    set_key CA-4405 VEFF-4583  # Green Brook Natural Area
    set_key CA-4406 VEFF-2725  # Green Island Nature Preserve
    set_key CA-4407 VEFF-4584  # Green River North Natural Area
    set_key CA-4408 VEFF-4585  # Greer Creek Natural Area
    set_key CA-4409 VEFF-4586  # Grew Brook Natural Area
    set_key CA-4410 VEFF-4587  # Halls Shed Lake Natural Area
    set_key CA-4411 VEFF-4588  # Hay Brook Natural Area
    set_key CA-4412 VEFF-4589  # Hells Gate Hardwoods Natural Area
    set_key CA-4413 VEFF-4590  # High Duck Island Natural Area
    set_key CA-4415 VEFF-4592  # Howard Brook Natural Area
    set_key CA-4416 VEFF-4593  # Indian Brook Natural Area
    set_key CA-4417 VEFF-2253  # Inkerman Migratory Bird Sanctuary
    set_key CA-4418 VEFF-4594  # Jardine Brook Natural Area
    set_key CA-4419 VEFF-4595  # Johnson's Mills Natural Area
    set_key CA-4420 VEFF-2737  # Kingston Family Nature Preserve
    set_key CA-4422 VEFF-4596  # Lake Stream Natural Area
    set_key CA-4423 VEFF-3797  # Lakeville Protected Area
    set_key CA-4424 VEFF-2259  # Lepreau River Wildlife Management Area
    set_key CA-4425 VEFF-4598  # Lewis Mountain Natural Area
    set_key CA-4426 VEFF-4600  # Little Cedar Brook Natural Area
    set_key CA-4427 VEFF-4601  # Little Forks Brook Natural Area
    set_key CA-4429 VEFF-4602  # Little River Natural Area
    set_key CA-4430 VEFF-3799  # Little Salmon River Protected Area
    set_key CA-4431 VEFF-4603  # Little Southwest Miramichi River Natural Area
    set_key CA-4432 VEFF-2260  # Little Tomoowa Lake Protected Area
    set_key CA-4433 VEFF-4604  # Lord and Foy Brook Natural Area
    set_key CA-4434 VEFF-4605  # Lower North Branch Little SW Miramichi River Natural Area
    set_key CA-4435 VEFF-4606  # MacFarlane Brook Natural Area
    set_key CA-4436 VEFF-2261  # Machias Seal Island Migratory Bird Sanctuary
    set_key CA-4437 VEFF-4607  # Magaguadavic River Natural Area
    set_key CA-4439 VEFF-4609  # Maxwell Natural Area
    set_key CA-4440 VEFF-4610  # McBean Brook Natural Area
    set_key CA-4441 VEFF-4611  # McCarty Brook Natural Area
    set_key CA-4442 VEFF-4615  # McLean Settlement Natural Area
    set_key CA-4443 VEFF-4612  # McCluskey Brook Natural Area
    set_key CA-4445 VEFF-4614  # McDougalls Brook Natural Area
    set_key CA-4446 VEFF-4616  # McManus Hill Natural Area
    set_key CA-4447 VEFF-4617  # McNeal Brook Natural Area
    set_key CA-4448 VEFF-4618  # McPhersons Point Natural Area
    set_key CA-4449 VEFF-4619  # Meduxnekeag Valley Natural Area
    set_key CA-4450 VEFF-4621  # Mill Brook Natural Area
    set_key CA-4451 VEFF-4622  # Mill Stream-Mactaquac Natural Area
    set_key CA-4452 VEFF-4623  # Miller Brook Natural Area
    set_key CA-4454 VEFF-4625  # Monument Brook Natural Area
    set_key CA-4455 VEFF-4626  # Moose Valley Hill Natural Area
    set_key CA-4456 VEFF-4627  # Mount Akroyd Natural Area
    set_key CA-4457 VEFF-4628  # Mount Denys Natural Area
    set_key CA-4458 VEFF-4629  # Mount Elizabeth Natural Area
    set_key CA-4459 VEFF-4630  # Mount Tom Natural Area
    set_key CA-4461 VEFF-4631  # Musquash Estuary, Crown Land Component
    set_key CA-4465 VEFF-4633  # Nashwaak River Natural Area
    set_key CA-4467 VEFF-4635  # New River Natural Area
    set_key CA-4468 VEFF-4636  # Nictau Natural Area
    set_key CA-4469 VEFF-4637  # North and South Green Islands Natural Area
    set_key CA-4470 VEFF-4638  # North Branch Burnt Church River Natural Area
    set_key CA-4471 VEFF-4639  # North Lake Natural Area
    set_key CA-4472 VEFF-4640  # North Pole Stream Natural Area
    set_key CA-4473 VEFF-4641  # Northwest Upsalquitch River Natural Area
    set_key CA-4474 VEFF-4642  # Oak Mountain Natural Area
    set_key CA-4476 VEFF-4644  # Oven Rock Brook Natural Area
    set_key CA-4477 VEFF-3802  # Ovenhead Protected Area
    set_key CA-4478 VEFF-4645  # Partridge Valley East Natural Area
    set_key CA-4479 VEFF-4646  # Partridge Valley West Natural Area
    set_key CA-4480 VEFF-4647  # Patapedia River Natural Area
    set_key CA-4481 VEFF-4648  # Patchell Brook Natural Area
    set_key CA-4482 VEFF-2267  # Phillipstown Protected Natural Area
    set_key CA-4483 VEFF-4649  # Picadilly Mountain Natural Area
    set_key CA-4484 VEFF-4650  # Pisiguit Brook Natural Area
    set_key CA-4485 VEFF-4651  # Pocologan Natural Area
    set_key CA-4486 VEFF-4652  # Pocowogamis Stream Natural Area
    set_key CA-4487 VEFF-4653  # Point Wolfe River Gorge Natural Area
    set_key CA-4488 VEFF-4654  # Pokiok River Natural Area
    set_key CA-4489 VEFF-4655  # Pokiok Stream Natural Area
    set_key CA-4490 VEFF-4656  # Pollard Brook Natural Area
    set_key CA-4491 VEFF-4657  # Popelogan Depot Natural Area
    set_key CA-4492 VEFF-4658  # Porcupine Mountain Natural Area
    set_key CA-4494 VEFF-4660  # Quigley Brook Natural Area
    set_key CA-4495 VEFF-4661  # Quisibis Mountain Natural Area
    set_key CA-4497 VEFF-4663  # Ragged Falls Natural Area
    set_key CA-4498 VEFF-4664  # Red Pine Brook Natural Area
    set_key CA-4499 VEFF-4665  # Richibucto River Natural Area
    set_key CA-4500 VEFF-4666  # Risteen Brook Natural Area
    set_key CA-4501 VEFF-4667  # River de Chute Natural Area
    set_key CA-4503 VEFF-4668  # Saddleback Brook Natural Area
    set_key CA-4505 VEFF-4670  # Salkeld Islands Natural Area
    set_key CA-4508 VEFF-4673  # Shikatehawk Stream Natural Area
    set_key CA-4509 VEFF-4674  # Shinnickburn Natural Area
    set_key CA-4510 VEFF-4675  # Sills Brook Natural Area
    set_key CA-4511 VEFF-4676  # Skiff Lake Natural Area
    set_key CA-4512 VEFF-4677  # Smith Brook Natural Area
    set_key CA-4513 VEFF-4678  # South Branch Big Sevogle River Natural Area
    set_key CA-4514 VEFF-4679  # South Branch Burnt Church River Natural Area
    set_key CA-4515 VEFF-4322  # South Kedgwick River
    set_key CA-4516 VEFF-2776  # South Wolf Island Nature Preserve Protected Area
    set_key CA-4517 VEFF-4680  # Spednic Lake Natural Area
    set_key CA-4518 VEFF-4681  # Spud Brook Natural Area
    set_key CA-4520 VEFF-4682  # Stickney Natural Area
    set_key CA-4521 VEFF-4683  # Stillwater Brook Natural Area
    set_key CA-4524 VEFF-4686  # Tabusintac Natural Area
    set_key CA-4525 VEFF-4687  # Tabusintac River Natural Area
    set_key CA-4527 VEFF-4688  # Tamarack Brook Natural Area
    set_key CA-4528 VEFF-4689  # Tauadook River Natural Area
    set_key CA-4529 VEFF-4690  # Tay River Natural Area
    set_key CA-4530 VEFF-4313  # Enclosure Park Historic Site
    set_key CA-4531 VEFF-4691  # Trout Brook Natural Area
    set_key CA-4532 VEFF-4692  # Two Mile Brook Fen Natural Area
    set_key CA-4533 VEFF-4693  # Upham Brook Natural Area
    set_key CA-4534 VEFF-4694  # Upper Dungarvon River Natural Area
    set_key CA-4535 VEFF-4695  # Upper Salmon River Natural Area
    set_key CA-4536 VEFF-4696  # Upper Thorn Point Brook Natural Area
    set_key CA-4537 VEFF-4697  # Welch Brook Natural Area
    set_key CA-4538 VEFF-4698  # West Branch Coy Brook Natural Area
    set_key CA-4539 VEFF-4699  # Western Green Island Natural Area
    set_key CA-4542 VEFF-2281  # Woodman Protected Area
    set_key CA-4543 VEFF-2284  # Bay du Nord Wilderness Reserve
    set_key CA-4544 VEFF-2787  # Big Barasway Wildlife Reserve
    set_key CA-4549 VEFF-2790  # Grand Codroy Estuary Wilderness Preserve
    set_key CA-4550 VEFF-1307  # Grand Codroy Provincial Park
    set_key CA-4551 VEFF-2792  # Hare Bay Islands Ecological Reserve
    set_key CA-4552 VEFF-4326  # Île aux Canes Migratory Bird Sanctuary
    set_key CA-4553 VEFF-1299  # Bowring Park
    set_key CA-4554 VEFF-2794  # Lawn Bay Ecological Reserve
    set_key CA-4555 VEFF-2795  # Little Grand Lake Ecological Reserve
    set_key CA-4557 VEFF-2796  # Main River Special Management Area
    set_key CA-4558 VEFF-2296  # Middle Ridge Wildlife Reserve
    set_key CA-4559 VEFF-1311  # Mistaken Point Ecological Reserve
    set_key CA-4560 VEFF-2297  # Salmonier Nature Park
    set_key CA-4561 VEFF-1315  # Sandy Cove Ecological Reserve
    set_key CA-4564 VEFF-2299  # Terra Nova Migratory Bird Sanctuary
    set_key CA-4566 VEFF-2302  # Akimiski Island Bird Sanctuary
    set_key CA-4569 VEFF-2803  # Bylot Island Bird Sanctuary
    set_key CA-4572 VEFF-2305  # Dewey Soper Bird Sanctuary
    set_key CA-4573 VEFF-2306  # East Bay Bird Sanctuary
    set_key CA-4577 VEFF-2307  # Harry Gibbons Bird Sanctuary
    set_key CA-4581 VEFF-2805  # McConnell River (Kuugaayuk) Bird Sanctuary
    set_key CA-4586 VEFF-2806  # Prince Leopold Island Migratory Bird Sanctuary
    set_key CA-4587 VEFF-2310  # Queen Maud Gulf (Ahiak) Bird Sanctuary
    set_key CA-4588 VEFF-1322  # Rasmussen Lowlands Wilderness Preserve
    set_key CA-4589 VEFF-2311  # Seymour Island Bird Sanctuary
    set_key CA-4594 VEFF-5258  # Tallurutiup Imanga National Marine Conservation Area
    set_key CA-4595 VEFF-1323  # Tamaarvik Territorial Park
    set_key CA-4596 VEFF-1324  # Taqaiqsirvik Territorial Park
    set_key CA-4598 VEFF-1325  # Tupirvik Territorial Park
    set_key CA-4599 VEFF-4328  # Twin Islands Wildlife Sanctuary
    set_key CA-4602 VEFF-4724  # Conrad Campground
    set_key CA-4603 VEFF-1415  # Devils' Elbow / Big Island Habitat Protection Area
    set_key CA-4604 VEFF-1414  # Ddhaw Ghro Habitat Protection Area
    set_key CA-4605 VEFF-2689  # Ezodziti Habitat Protection Area
    set_key CA-4607 VEFF-1419  # Fort Selkirk Habitat Protection Area
    set_key CA-4609 VEFF-1417  # Horseshoe Slough (Nuna K'ohonete Yedak Tah'e) Habitat Protection Area
    set_key CA-4610 VEFF-2313  # Kookatsoon Lake Recreation Site
    set_key CA-4611 VEFF-2314  # Lewes Marsh Habitat Protection Area
    set_key CA-4612 VEFF-2808  # Lhutsaw (Lutsaw) Wetland Habitat Protection Area
    set_key CA-4613 VEFF-2315  # Liard Canyon Recreation Site
    set_key CA-4614 VEFF-2316  # Marsh Lake Recreation Site
    set_key CA-4615 VEFF-2317  # Morley River Recreation Site
    set_key CA-4616 VEFF-1421  # Nisutlin River Recreation Site
    set_key CA-4617 VEFF-2809  # Ni'iinlii Njik (Fishing Branch) Territorial Park
    set_key CA-4619 VEFF-2813  # T'aw Ta'ar National Historic Site
    set_key CA-4621 VEFF-1422  # Nordenskiold Wetland (Ts'alwnjik Chu) Habitat Protection Area
    set_key CA-4623 VEFF-1423  # Old Crow Flats (Van Tat K'atr'anahtii) Habitat Protection Area
    set_key CA-4624 VEFF-2810  # Otter Falls Recreation Site
    set_key CA-4625 VEFF-1424  # Pickhandle Lakes Habitat Protection Area
    set_key CA-4626 VEFF-1425  # Rampart House Habitat Protection Area
    set_key CA-4627 VEFF-2811  # Rancheria Falls Recreation site
    set_key CA-4628 VEFF-2812  # Spruce Beetle Trail Habitat Protection Area
    set_key CA-4629 VEFF-2814  # Ta'Tla Mun Special Management Area
    set_key CA-4636 VEFF-1430  # Tombstone Territorial Park
    set_key CA-4637 VEFF-2816  # Whitefish Wetland (Ch'ihilii Chik) Habitat Protection Area
    set_key CA-4640 VEFF-2322  # Adams Pond Natural Area
    set_key CA-4641 VEFF-2323  # Afton Lake Natural Area
    set_key CA-4646 VEFF-1809  # Beach Grove Memorial Forest Natural Area
    set_key CA-4649 VEFF-1810  # Black Pond Migratory Bird Sanctuary
    set_key CA-4651 VEFF-2324  # Boughton River Riparian Zone Natural Area
    set_key CA-4657 VEFF-2828  # St. Peters Harbour National Historic Site
    set_key CA-4665 VEFF-2821  # DeRoche Pond Natural Area
    set_key CA-4667 VEFF-1814  # Dingwells Mills Wildlife Management Area
    set_key CA-4668 VEFF-2823  # Docs Marsh/Forest Hills Natural Area
    set_key CA-4673 VEFF-3290  # East Lake Sand Dunes Natural Area
    set_key CA-4674 VEFF-4330  # Ellens Creek Estuary Natural Area
    set_key CA-4675 VEFF-2325  # Ellerslie Bog Natural Area
    set_key CA-4677 VEFF-1829  # Strathgartney Homestead National Historic Site
    set_key CA-4682 VEFF-2824  # Grovepine / Big Brook Wildlife Management Area
    set_key CA-4688 VEFF-3301  # Howe Point Coastal Cliff Natural Area
    set_key CA-4694 VEFF-1329  # Larkins Pond Natural Area
    set_key CA-4702 VEFF-3308  # MacLeans Pond Natural Area
    set_key CA-4707 VEFF-2327  # Martinvale-Corraville Wildlife Management Area
    set_key CA-4712 VEFF-2328  # Montague Wildlife Management Area
    set_key CA-4716 VEFF-2329  # Mount Stewart Wildlife Management Area
    set_key CA-4736 VEFF-1824  # Province House National Historic Site
    set_key CA-4739 VEFF-2826  # River Wetlands Wildlife Management Area
    set_key CA-4744 VEFF-1825  # Royalty Oaks Natural Area
    set_key CA-4748 VEFF-1830  # Tryon United Church National Historic Site
    set_key CA-4752 VEFF-2331  # Southampton Wildlife Management Area
    set_key CA-4755 VEFF-2330  # St. Chrysostome (Saint Chrysostome) Wildlife Management Area
    set_key CA-4756 VEFF-2827  # St. Peters Bog Natural Area
    set_key CA-4757 VEFF-2829  # St. Peters Island Natural Area
    set_key CA-4762 VEFF-2831  # Trout River Riparian Zone Natural Area
    set_key CA-4766 VEFF-1330  # Victoria Park Natural Area
    set_key CA-4771 VEFF-1576  # Abbot Pass Refuge Cabin National Historic Site
    set_key CA-4772 VEFF-1580  # Athabasca Pass National Historic Site
    set_key CA-4773 VEFF-1582  # Banff Park Museum National Historic Site
    set_key CA-4774 VEFF-1583  # Bar U Ranch National Historic Site
    set_key CA-4775 VEFF-1593  # Cave and Basin National Historic Site
    set_key CA-4776 VEFF-1598  # First Oil Well in Western Canada National Historic Site
    set_key CA-4777 VEFF-1600  # Frog Lake National Historic Site
    set_key CA-4778 VEFF-1603  # Howse Pass National Historic Site
    set_key CA-4779 VEFF-1604  # Jasper House National Historic Site
    set_key CA-4780 VEFF-1605  # Jasper Park Information Centre National Historic Site
    set_key CA-4781 VEFF-1606  # Maligne Lake Chalet and Guest House National Historic Site
    set_key CA-4782 VEFF-1608  # Rocky Mountain House National Historic Site
    set_key CA-4783 VEFF-1609  # Skoki Ski Lodge National Historic Site
    set_key CA-4784 VEFF-1610  # Sulphur Mountain Cosmic Ray Station National Historic Site
    set_key CA-4786 VEFF-1624  # Chilkoot Trail National Historic Site
    set_key CA-4787 VEFF-1644  # Fisgard Lighthouse National Historic Site
    set_key CA-4788 VEFF-1646  # Fort Langley National Historic Site
    set_key CA-4789 VEFF-1647  # Fort Rodd Hill National Historic Site
    set_key CA-4790 VEFF-1648  # Fort St. James National Historic Site
    set_key CA-4791 VEFF-1654  # Gitwangak Battle Hill National Historic Site
    set_key CA-4792 VEFF-1657  # Gulf of Georgia Cannery National Historic Site
    set_key CA-4793 VEFF-1677  # Kicking Horse Pass National Historic Site
    set_key CA-4794 VEFF-1685  # Kootenae House National Historic Site
    set_key CA-4795 VEFF-1707  # Nan Sdins National Historic Site
    set_key CA-4796 VEFF-1721  # Rogers Pass National Historic Site
    set_key CA-4797 VEFF-1738  # Stanley Park National Historic Site
    set_key CA-4798 VEFF-1751  # Twin Falls Tea House National Historic Site
    set_key CA-4799 VEFF-1544  # Forts Rouge, Garry and Gibraltar National Historic Site
    set_key CA-4800 VEFF-1545  # Linear Mounds National Historic Site
    set_key CA-4803 VEFF-1551  # Riding Mountain Park East Gate Registration Complex N.H.S.
    set_key CA-4805 VEFF-1552  # St. Andrew's Rectory National Historic Site
    set_key CA-4808 VEFF-1763  # Beaubears Island Shipbuilding N.H.S. [aka J. Leonard O'Brien Memorial]
    set_key CA-4809 VEFF-1765  # Boishebert National Historic Site
    set_key CA-4810 VEFF-1766  # Carleton Martello Tower N.H.S.
    set_key CA-4811 VEFF-1768  # Fort Beausejour - Fort Cumberland N.H.S.
    set_key CA-4812 VEFF-1770  # Fort Gaspareaux N.H.S.
    set_key CA-4813 VEFF-1778  # La Coupe Dry Dock National Historic Site
    set_key CA-4814 VEFF-1782  # Monument-Lefebvre National Historic Site
    set_key CA-4815 VEFF-1783  # St. Andrews Blockhouse National Historic Site
    set_key CA-4816 VEFF-1786  # Cape Spear Lighthouse National Historic Site
    set_key CA-4817 VEFF-1787  # Castle Hill National Historic Site
    set_key CA-4818 VEFF-1791  # Hawthorne Cottage National Historic Site
    set_key CA-4819 VEFF-1793  # Hopedale Mission National Historic Site
    set_key CA-4820 VEFF-1794  # Kitjigattalik - Ramah Chert Quarries N.H.S.
    set_key CA-4821 VEFF-1795  # L'Anse aux Meadows National Historic Site
    set_key CA-4822 VEFF-1797  # Port au Choix National Historic Site
    set_key CA-4823 VEFF-1798  # Red Bay National Historic Site
    set_key CA-4824 VEFF-1799  # Ryan Premises National Historic Site
    set_key CA-4825 VEFF-1800  # Signal Hill National Historic Site
    set_key CA-4826 VEFF-1432  # Alexander Graham Bell National Historic Site
    set_key CA-4827 VEFF-2334  # Beaubassin National Historic Site
    set_key CA-4828 VEFF-1434  # Bloody Creek National Historic Site
    set_key CA-4829 VEFF-1844  # Canso Islands National Historic Site
    set_key CA-4830 VEFF-1439  # Charles Fort National Historic Site
    set_key CA-4831 VEFF-1443  # D'Anville's Encampment National Historic Site
    set_key CA-4832 VEFF-1446  # Fort Anne National Historic Site
    set_key CA-4833 VEFF-1447  # Fort Edward National Historic Site
    set_key CA-4834 VEFF-1448  # Fort Lawrence National Historic Site
    set_key CA-4835 VEFF-1449  # Fort McNab National Historic Site
    set_key CA-4836 VEFF-1450  # Fort Sainte Marie de Grace N.H.S.
    set_key CA-4837 VEFF-1451  # Fortress of Louisbourg National Historic Site
    set_key CA-4838 VEFF-1453  # Georges Island National Historic Site
    set_key CA-4839 VEFF-1454  # Grand-Pre National Historic Site
    set_key CA-4840 VEFF-1455  # Grassy Island Fort National Historic Site
    set_key CA-4841 VEFF-1457  # Halifax Citadel National Historic Site
    set_key CA-4842 VEFF-1461  # Marconi National Historic Site
    set_key CA-4843 VEFF-2347  # Melanson Settlement National Historic Site
    set_key CA-4844 VEFF-1471  # Port-Royal National Historic Site
    set_key CA-4845 VEFF-1472  # Prince of Wales Tower National Historic Site
    set_key CA-4846 VEFF-1474  # Royal Battery National Historic Site
    set_key CA-4847 VEFF-1477  # St. Peters National Historic Site
    set_key CA-4848 VEFF-1478  # St. Peters Canal National Historic Site
    set_key CA-4849 VEFF-2359  # Wolfe's Landing National Historic Site
    set_key CA-4850 VEFF-1490  # York Redoubt National Historic Site
    set_key CA-4851 VEFF-1761  # Saoyu-Ehdacho National Historic Site
    set_key CA-4853 VEFF-1338  # Battle Hill National Historic Site
    set_key CA-4855 VEFF-2549  # Battle of the Windmill National Historic Site
    set_key CA-4856 VEFF-4362  # Battlefield of Fort George N.H.S.
    set_key CA-4857 VEFF-2550  # Beausoleil Island National Historic Site
    set_key CA-4858 VEFF-1344  # Bellevue House National Historic Site
    set_key CA-4859 VEFF-4365  # Bethune Memorial House N.H.S.
    set_key CA-4860 VEFF-2554  # Bois Blanc Island Lighthouse and Blockhouse National Historic Site
    set_key CA-4861 VEFF-4367  # Butler's Barracks N.H.S.
    set_key CA-4862 VEFF-1347  # Carrying Place of the Bay of Quinte N.H.S.
    set_key CA-4863 VEFF-1355  # Fort George National Historic Site
    set_key CA-4864 VEFF-1356  # Fort Henry National Historic Site
    set_key CA-4865 VEFF-1357  # Fort Malden National Historic Site
    set_key CA-4866 VEFF-1358  # Fort Mississauga National Historic Site
    set_key CA-4867 VEFF-4386  # Fort St. Joseph N.H.S.
    set_key CA-4868 VEFF-1359  # Fort Wellington National Historic Site
    set_key CA-4870 VEFF-1372  # HMCS Haida National Historic Site
    set_key CA-4872 VEFF-1377  # Kingston Fortifications National Historic Site
    set_key CA-4873 VEFF-2581  # Laurier House National Historic Site
    set_key CA-4875 VEFF-1382  # Mississauga Point Lighthouse National Historic Site
    set_key CA-4876 VEFF-4946  # Mnjikaning Fish Weirs N.H.S.
    set_key CA-4877 VEFF-1383  # Murney Tower National Historic Site
    set_key CA-4878 VEFF-4410  # Navy Island N.H.S.
    set_key CA-4879 VEFF-1391  # Peterborough Lift Lock National Historic Site
    set_key CA-4880 VEFF-1392  # Point Clark Lighthouse National Historic Site
    set_key CA-4881 VEFF-1394  # Queenston Heights National Historic Site
    set_key CA-4882 VEFF-2593  # Rideau Canal National Historic Site
    set_key CA-4883 VEFF-4951  # Ridgeway Battlefield N.H.S.
    set_key CA-4884 VEFF-1396  # Saint-Louis Mission National Historic Site
    set_key CA-4885 VEFF-1397  # Sault Ste. Marie Canal National Historic Site
    set_key CA-4886 VEFF-1398  # Shoal Tower National Historic Site
    set_key CA-4888 VEFF-1956  # Southwold Earthworks National Historic Site
    set_key CA-4890 VEFF-1410  # Woodside National Historic Site
    set_key CA-4891 VEFF-1808  # Ardgowan National Historic Site
    set_key CA-4892 VEFF-1813  # Dalvay-by-the-Sea National Historic Site
    set_key CA-4893 VEFF-1823  # L.M. Montgomery's Cavendish N.H.S. (Green Gables Heritage Place)
    set_key CA-4894 VEFF-1827  # Skmaqn-Port-la-Joye-Fort Amherst N.H.S.
    set_key CA-4896 VEFF-1492  # Battle of the Chateauguay National Historic Site
    set_key CA-4897 VEFF-1493  # Battle of the Restigouche National Historic Site
    set_key CA-4898 VEFF-1495  # Carillon Barracks National Historic Site
    set_key CA-4899 VEFF-1496  # Carillon Canal National Historic Site
    set_key CA-4900 VEFF-1497  # Cartier-Brebeuf National Historic Site
    set_key CA-4901 VEFF-1498  # Chambly Canal National Historic Site
    set_key CA-4902 VEFF-1500  # Coteau-du-Lac National Historic Site
    set_key CA-4903 VEFF-1501  # Forges du Saint-Maurice National Historic Site
    set_key CA-4904 VEFF-1502  # Fort Chambly National Historic Site
    set_key CA-4905 VEFF-1503  # Fort Lennox National Historic Site
    set_key CA-4906 VEFF-1491  # 57-63 St. Louis Street National Historic Site
    set_key CA-4907 VEFF-1504  # Fort Ste. Therese National Historic Site
    set_key CA-4908 VEFF-1505  # Fort Temiscamingue National Historic Site
    set_key CA-4909 VEFF-1506  # Fortifications of Québec N.H.S.
    set_key CA-4910 VEFF-1507  # Grosse Ile and the Irish Memorial N.H.S.
    set_key CA-4911 VEFF-1508  # Lachine Canal National Historic Site
    set_key CA-4912 VEFF-1509  # Levis Forts National Historic Site
    set_key CA-4913 VEFF-1511  # Louis S. St. Laurent National Historic Site
    set_key CA-4914 VEFF-1510  # Louis-Joseph Papineau National Historic Site
    set_key CA-4915 VEFF-1512  # Maillou House National Historic Site
    set_key CA-4916 VEFF-1513  # Manoir Papineau National Historic Site
    set_key CA-4917 VEFF-1514  # Montmorency Park National Historic Site
    set_key CA-4918 VEFF-1522  # Pointe-au-Pere Lighthouse National Historical Site
    set_key CA-4919 VEFF-1523  # Quebec Garrison Club National Historic Site
    set_key CA-4920 VEFF-1536  # Sainte-Anne-de-Bellevue Canal National Historic Site
    set_key CA-4921 VEFF-1534  # Saint-Louis Forts and Chateaux N.H.S.
    set_key CA-4922 VEFF-1535  # Saint-Ours Canal National Historic Site
    set_key CA-4923 VEFF-1537  # Sir George-Etienne Cartier N.H.S.
    set_key CA-4924 VEFF-1538  # Sir Wilfrid Laurier National Historic Site
    set_key CA-4925 VEFF-1539  # The Fur Trade at Lachine National Historic Site
    set_key CA-4926 VEFF-1560  # Batoche National Historic Site
    set_key CA-4927 VEFF-1561  # Battle of Tourond's Coulee / Fish Creek N.H.S.
    set_key CA-4928 VEFF-1563  # Cypress Hills Massacre National Historic Site
    set_key CA-4929 VEFF-1564  # Fort Battleford National Historic Site
    set_key CA-4930 VEFF-1566  # Fort Esperance National Historic Site
    set_key CA-4931 VEFF-1567  # Fort Livingstone National Historic Site
    set_key CA-4932 VEFF-1568  # Fort Pelly National Historic Site
    set_key CA-4933 VEFF-1569  # Fort Walsh National Historic Site
    set_key CA-4934 VEFF-1570  # Frenchman Butte National Historic Site
    set_key CA-4936 VEFF-1413  # Dawson Historical Complex National Historic Site
    set_key CA-4937 VEFF-1416  # Dredge No. 4 National Historic Site
    set_key CA-4938 VEFF-1418  # Former Territorial Court House National Historic Site
    set_key CA-4939 VEFF-1427  # S.S. Keno National Historic Site
    set_key CA-4940 VEFF-1428  # S.S. Klondike National Historic Site
    set_key CA-4942 VEFF-3816  # Captain James Cook National Historic Site
    set_key CA-4943 VEFF-1775  # Fort Nerepis National Historic Site
    set_key CA-4944 VEFF-1771  # Fort Howe National Historic Site
    set_key CA-4945 VEFF-3381  # Base de plein air Sainte-Foy
    set_key CA-4946 VEFF-2384  # Canyon des Portes de l'Enfer
    set_key CA-4947 VEFF-2432  # Parc Nature Eco-Odyssee
    set_key CA-4948 VEFF-2446  # Parc regional du Mont-Saint-Joseph
    set_key CA-4951 VEFF-2396  # Parc de Gros-Cap
    set_key CA-4952 VEFF-2397  # Parc de la caverne Trou de la Fee
    set_key CA-4953 VEFF-2400  # Parc de la Gorge de Coaticook
    set_key CA-4954 VEFF-2404  # Parc de la Riviere de Terrebonne
    set_key CA-4955 VEFF-2395  # Parc d'Escalade et de Randonnee de la Montagne d'Argent
    set_key CA-4956 VEFF-2407  # Parc des Chutes
    set_key CA-4957 VEFF-2408  # Parc des Chutes de Sainte-Ursule
    set_key CA-4958 VEFF-1518  # Parc des Chutes-Dorwin
    set_key CA-4959 VEFF-2423  # Parc Les Salines
    set_key CA-4960 VEFF-2428  # Parc Michel-Chartrand
    set_key CA-4961 VEFF-2433  # Parc Nature La Gabelle
    set_key CA-4962 VEFF-2434  # Parc naturel regional de Portneuf
    set_key CA-4963 VEFF-2435  # Parc regional de la Chute-a-Bull
    set_key CA-4964 VEFF-2436  # Parc regional de la riviere Gentilly
    set_key CA-4965 VEFF-2437  # Parc regional de la riviere Mitis
    set_key CA-4966 VEFF-2438  # Parc regional de la Seigneurie-du-Lac-Matapedia
    set_key CA-4967 VEFF-2439  # Parc regional des Grandes-Coulees
    set_key CA-4968 VEFF-2440  # Parc regional des Grandes-Rivieres du lac Saint-Jean
    set_key CA-4969 VEFF-2442  # Parc regional des Sept-Chutes
    set_key CA-4970 VEFF-2443  # Parc regional du Lac 31 Milles
    set_key CA-4971 VEFF-2444  # Parc regional du Lac Taureau
    set_key CA-4972 VEFF-1889  # Parc regional du Reservoir Kiamika
    set_key CA-4973 VEFF-2413  # Parc des Voltigeurs
    set_key CA-4974 VEFF-2417  # Parc du Sanctuaire St-Majorique
    set_key CA-4975 VEFF-2447  # Parc regional de la Foret Drummond
    set_key CA-4976 VEFF-2403  # Parc de la Riviere Batiscan
    set_key CA-4978 VEFF-2449  # Parc regional Saint-Bernard
    set_key CA-4979 VEFF-2419  # Parc ecologique Godefroy
    set_key CA-4980 VEFF-2385  # Marais Laperriere
    set_key CA-4982 VEFF-2410  # Parc des Chutes Rouillard
    set_key CA-4983 VEFF-2382  # La Foret recreative de Val d'Or
    set_key CA-4984 VEFF-3937  # Centre d'interprétation de la nature du Lac Boivin
    set_key CA-4985 VEFF-3410  # Parc historique de la Poudriere de Windsor
    set_key CA-4986 VEFF-2429  # Parc municipal de la Baie-des-Rochers
    set_key CA-4987 VEFF-2398  # Parc de la chute Sainte-Agathe-de-Lotbiniere
    set_key CA-4988 VEFF-2401  # Parc de la Promenade Bellerive
    set_key CA-4990 VEFF-2383  # Le Bois de l'equerre
    set_key CA-4992 VEFF-2372  # Foret Piche-Lemoine
    set_key CA-4994 VEFF-3939  # Parc Daniel-Johnson (Granby)
    set_key CA-4996 VEFF-3393  # Parc de la Riviere-Bourbon
    set_key CA-4997 VEFF-3407  # Parc ecomaritime de l'Anse-du-Port
    set_key CA-5003 VEFF-2448  # Parc regional Obalski
    set_key CA-5004 VEFF-2367  # Centre de plein air du Lac-Leamy
    set_key CA-5005 VEFF-2412  # Parc des Rapides
    set_key CA-5007 VEFF-2409  # Parc des Chutes-de-la-Chaudiere
    set_key CA-5009 VEFF-2458  # Refuge faunique Marguerite-D'Youville (Ile Saint-Bernard)
    set_key CA-5010 VEFF-2450  # Parc Rene-Levesque
    set_key CA-5019 VEFF-2441  # Parc regional des Iles-de-Saint-Timothee
    set_key CA-5023 VEFF-2368  # Centre ecologique Fernand-Seguin
    set_key CA-5029 VEFF-3409  # Parc historique de la Pointe-du-Moulin
    set_key CA-5031 VEFF-3382  # Centre ecologique de Port-au-Saumon
    set_key CA-5033 VEFF-2392  # Parc Bernard-Landry Regional Park
    set_key CA-5039 VEFF-2422  # Parc ecologique Le Renouveau Rosaire-Senecal
    set_key CA-5040 VEFF-2424  # Parc Lucien-Blanchard
    set_key CA-5041 VEFF-2445  # Parc regional du Mont Morissette
    set_key CA-5044 VEFF-1520  # Parc Ecoforestier de Johnville
    set_key CA-5045 VEFF-2371  # Domaine Taschereau - Parc nature
    set_key CA-5046 VEFF-3404  # Parc du Mont Arthabaska
    set_key CA-5048 VEFF-2414  # Parc du Bois-Beckett
    set_key CA-5052 VEFF-2430  # Parc Nature de Pointe-aux-Outardes
    set_key CA-5054 VEFF-2459  # Foret Montmorency
    set_key CA-5058 VEFF-2391  # Parc Beausejour Regional Park
    set_key CA-5059 VEFF-1515  # Parc d'Environnement Naturel de Sutton
    set_key CA-5065 VEFF-2370  # Domaine Saint-Bernard
    set_key CA-5075 VEFF-2386  # Marais Real-D.-Carbonneau
    set_key CA-5080 VEFF-3949  # Réseau du mont Oak
    set_key CA-5081 VEFF-3333  # International Appalachian Trail (IAT)
    set_key CA-5082 VEFF-3332  # The Great Trail of Canada (the Canadian Trailway)
    set_key CA-5083 VEFF-2567  # Diefenbunker National Historic Site
    set_key CA-5084 VEFF-2599  # South March Highlands Conservation Forest
    set_key CA-5085 VEFF-2275  # Stonehammer UNESCO Global Geopark
    set_key CA-5086 VEFF-2598  # Seymour Conservation Area
    set_key CA-5087 VEFF-2570  # Enniskillen Conservation Area
    set_key CA-5088 VEFF-3556  # King's Mill Conservation Area
    set_key CA-5089 VEFF-2596  # Sager Conservation Area
    set_key CA-5090 VEFF-2546  # Albion Hills Conservation Area
    set_key CA-5091 VEFF-2552  # Birdsall Wildlife Area
    set_key CA-5092 VEFF-2556  # Bruce's Caves Conservation Area
    set_key CA-5093 VEFF-2557  # Bruce's Mill Conservation Area
    set_key CA-5094 VEFF-2559  # Central Chambers National Historic Site
    set_key CA-5095 VEFF-2560  # Central Experimental Farm National Historic Site
    set_key CA-5096 VEFF-2563  # Claireville Conservation Area
    set_key CA-5097 VEFF-2565  # Confederation Square National Historic Site
    set_key CA-5099 VEFF-2571  # Forested Dunes Nature Reserve
    set_key CA-5100 VEFF-2572  # Glen Haffy Conservation Area
    set_key CA-5101 VEFF-2573  # Glenorchy Conservation Area
    set_key CA-5102 VEFF-2575  # Harold Town Conservation Area
    set_key CA-5103 VEFF-2576  # Heart Lake Conservation Area
    set_key CA-5104 VEFF-2578  # Hope Mill Conservation Area
    set_key CA-5105 VEFF-2579  # Kelso Conservation Area
    set_key CA-5106 VEFF-2580  # Langevin Block National Historical Site
    set_key CA-5107 VEFF-2582  # Mark's Bay Conservation Area
    set_key CA-5108 VEFF-2584  # Nashville Conservation Reserve
    set_key CA-5109 VEFF-2585  # National Arts Centre National Historic Site
    set_key CA-5110 VEFF-2586  # Notre-Dame Roman Catholic Basilica N.H.S.
    set_key CA-5111 VEFF-2587  # Oak Ridges Corridor Conservation Reserve
    set_key CA-5112 VEFF-2588  # Palgrave Forest and Wildlife Area
    set_key CA-5113 VEFF-2589  # Parliament Buildings National Historic Site
    set_key CA-5114 VEFF-2591  # Pier 4 Park
    set_key CA-5115 VEFF-2592  # Public Grounds of the Parliament Buildings N.H.S.
    set_key CA-5116 VEFF-2594  # Rideau Hall and Landscaped Grounds N.H.S.
    set_key CA-5117 VEFF-2595  # Royal Canadian Mint National Historic Site
    set_key CA-5118 VEFF-2597  # Selwyn Beach Conservation Area
    set_key CA-5119 VEFF-2604  # Assiniboine Forest Reserve
    set_key CA-5120 VEFF-2606  # Buhler Recreation Park
    set_key CA-5121 VEFF-2607  # Crescent Drive Park
    set_key CA-5122 VEFF-2608  # Fraser's Grove Park
    set_key CA-5123 VEFF-2609  # Kilcona Park
    set_key CA-5124 VEFF-2612  # La Barriere Park
    set_key CA-5125 VEFF-2613  # Little Mountain Park
    set_key CA-5126 VEFF-2614  # Maple Grove Park
    set_key CA-5127 VEFF-2615  # Neepawa Court House / Beautiful Plains County Court Building N.H.S.
    set_key CA-5129 VEFF-2620  # Shirley Render Park
    set_key CA-5130 VEFF-2625  # Big Manitou Regional Park
    set_key CA-5131 VEFF-2637  # Melville Railway Station National Historic Site
    set_key CA-5132 VEFF-2295  # L'Anse Amour National Historic Site
    set_key CA-5134 VEFF-3215  # Gateway Wetland Nature Trails and Conservation Centre
    set_key CA-5135 VEFF-3256  # Sir Douglas Hazen Recreation Park
    set_key CA-5136 VEFF-3791  # Fort Hughes Military Blockhouse National Historic Site
    set_key CA-5137 NIL-0000  # Thatch Road (MacDougall) Trail; WWFF candidates: VEFF-3258, VEFF-3811
    set_key CA-5138 VEFF-2266  # O'Dell Park Recreation Park
    set_key CA-5139 VEFF-2640  # Saskatchewan Legislative Building and Grounds N.H.S.
    set_key CA-5140 VEFF-2641  # Saskatoon Railway Station (Canadian Pacific) N.H.S.
    set_key CA-5141 VEFF-2979  # Lemoine Point Conservation Area
    set_key CA-5142 VEFF-2986  # Parrott's Bay Conservation Area
    set_key CA-5143 VEFF-2983  # Marshlands Conservation Area
    set_key CA-5144 VEFF-2655  # Gooseberry Lake Provincial Park
    set_key CA-5145 VEFF-2660  # Maskepetoon Park Natural Area
    set_key CA-5146 VEFF-2671  # Watson Creek Provincial Park
    set_key CA-5147 VEFF-2694  # 1 Chipman Hill N.H.S.
    set_key CA-5148 VEFF-2695  # Arts Building National Historic Site
    set_key CA-5149 VEFF-2696  # Bayswater Lighthouse National Heritage Site
    set_key CA-5150 VEFF-2697  # Beardsley Hill Protected Area
    set_key CA-5151 VEFF-2698  # Beausoleil Protected Area
    set_key CA-5152 VEFF-2699  # Beldings Reef Protected Area
    set_key CA-5153 VEFF-2700  # Butternut Island Protected Area
    set_key CA-5154 VEFF-2701  # Cape Jourimain Lighthouse National Heritage Site
    set_key CA-5155 VEFF-2702  # Chandler House / Rocklyn National Historic Site
    set_key CA-5156 VEFF-2703  # Christ Church Anglican National Historic Site
    set_key CA-5157 VEFF-2704  # Christ Church Cathedral National Historic Site
    set_key CA-5158 VEFF-2705  # Clark Gregory Protected Area
    set_key CA-5159 VEFF-2706  # Connell House National Historic Site
    set_key CA-5160 VEFF-2707  # Connell Park
    set_key CA-5161 VEFF-2708  # Connors Bros. Preserve
    set_key CA-5162 VEFF-2709  # Coronation Park
    set_key CA-5163 VEFF-2710  # Denys Fort / Habitation National Historic Site
    set_key CA-5164 VEFF-2711  # Dick's Island Protected Area
    set_key CA-5165 VEFF-2712  # Dolan Woodlands Protected Area
    set_key CA-5166 VEFF-2713  # Dominion Park Recreation Park
    set_key CA-5167 VEFF-2714  # Eagle's Eye Protected Area
    set_key CA-5169 VEFF-2715  # East Riverside Kingshurst Park Recreation Park
    set_key CA-5170 VEFF-2716  # Fallsview Park Recreation Park
    set_key CA-5171 VEFF-2717  # Ferris Street Forest and Wetland Protected Area
    set_key CA-5172 VEFF-2718  # Fredericton Botanic Garden Conservation Area
    set_key CA-5173 VEFF-2719  # Fredericton Military Compound N.H.S.
    set_key CA-5174 VEFF-2720  # Fredericton Railway Bridge (Bill Thorpe Walking Bridge)
    set_key CA-5175 VEFF-2721  # Free Meeting House National Historic Site
    set_key CA-5176 VEFF-2722  # Frye Island Protected Area
    set_key CA-5177 VEFF-2723  # Frye Lake Nature Reserve
    set_key CA-5178 VEFF-2724  # George M Stirrett Protected Area
    set_key CA-5179 VEFF-2726  # Greenock Church National Historic Site
    set_key CA-5180 VEFF-2727  # Hammond House National Historic Site
    set_key CA-5181 VEFF-2728  # Hammond River Park
    set_key CA-5182 VEFF-2729  # Hampton Marsh Protected Area
    set_key CA-5183 VEFF-2730  # Hanwell Recreation Park
    set_key CA-5184 VEFF-2731  # Henry Park
    set_key CA-5185 VEFF-2732  # Imperial / Bi-Capitol Theatre N.H.S.
    set_key CA-5186 VEFF-2733  # Inch Arran Point Front Range National Historic Site
    set_key CA-5187 VEFF-2734  # Joseph Allain Protected Area
    set_key CA-5188 VEFF-2735  # Jordan Miller Park
    set_key CA-5189 VEFF-2736  # Kingsbrae Garden Conservation Area
    set_key CA-5190 VEFF-2738  # Little River Reservoir Park
    set_key CA-5191 VEFF-2739  # Long Eddy Point National Historic Site
    set_key CA-5192 VEFF-2740  # Machias Seal Island Heritage lighthouse
    set_key CA-5193 VEFF-2741  # Malloy Field Recreation Park
    set_key CA-5194 VEFF-2742  # Manawagonish Island Protected Area
    set_key CA-5195 VEFF-2743  # Mapleton Acadian Forest Protected Area
    set_key CA-5196 VEFF-2744  # Margeret (Coburn) Cameron Woods
    set_key CA-5197 VEFF-2745  # Marine Hospital National Historic Site
    set_key CA-5198 VEFF-2746  # Marysville Cotton Mill National Historic Site
    set_key CA-5199 VEFF-2747  # Marysville Historic District National Historic Site
    set_key CA-5200 VEFF-2748  # McAdam Railway Station (Canadian Pacific) N.H.S.
    set_key CA-5201 VEFF-2749  # Ministers Island National Historic Site
    set_key CA-5202 VEFF-2750  # Ministers Island Pre-contact Sites N.H.S.
    set_key CA-5203 VEFF-2751  # Miscou Island Lighthouse National Historic Site
    set_key CA-5204 VEFF-2752  # Nashwaaksis Stream Nature Park
    set_key CA-5205 VEFF-2753  # Navy Island &amp; Leigh Williamson Protected Area
    set_key CA-5207 VEFF-2755  # New River Island Protected Area
    set_key CA-5208 VEFF-2756  # Noloqonokek Protected Area
    set_key CA-5209 VEFF-2757  # Noremac Habitat Protected Area
    set_key CA-5210 VEFF-2758  # Number 2 Mechanics' Volunteer Company Engine House N.H.S.
    set_key CA-5211 VEFF-2760  # Officers' Square Recreation Park
    set_key CA-5212 VEFF-2761  # Old Government House National Historic Site
    set_key CA-5213 VEFF-2762  # Ordnance Building National Historic Site
    set_key CA-5214 VEFF-2763  # Partridge Island Quarantine Station N.H.S.
    set_key CA-5215 VEFF-2764  # Prince William Streetscape National Historic Site
    set_key CA-5216 VEFF-2765  # Rayworth Beach Protected Area
    set_key CA-5217 VEFF-2766  # Reading Street Park
    set_key CA-5218 VEFF-2767  # Reg Bonney Protected Area
    set_key CA-5219 VEFF-2768  # Riverview Memorial Park
    set_key CA-5220 VEFF-2769  # Rothesay Railway Station (European and North American) N.H.S.
    set_key CA-5221 VEFF-2770  # Saint John City Market N.H.S.
    set_key CA-5222 VEFF-2771  # Saint John County Court House National Historic Site
    set_key CA-5223 VEFF-2772  # Sand Point National Historic Site
    set_key CA-5224 VEFF-2773  # Seaside Park
    set_key CA-5225 VEFF-2774  # Seymour Woodlands Protected Area
    set_key CA-5226 VEFF-2775  # Slippery Mitten Protected Area
    set_key CA-5227 VEFF-2777  # St. Andrews Historic District National Historic Site
    set_key CA-5228 VEFF-2778  # St. Luke's Anglican Church National Historic Site
    set_key CA-5229 VEFF-2779  # St. Paul's United Church National Historic Site
    set_key CA-5230 VEFF-2780  # St. Stephen Post Office National Historic Site
    set_key CA-5231 VEFF-2781  # Thompson Marsh Protected Area
    set_key CA-5232 VEFF-2782  # Tilley House National Historic Site
    set_key CA-5233 VEFF-2783  # Mahsusuwi-monihkuk Nature Preserve (Ex. Tobique Island)
    set_key CA-5234 VEFF-2784  # Tonge's Island National Historic Site
    set_key CA-5235 VEFF-2785  # Warren Kent Coleman Protected Area
    set_key CA-5236 VEFF-2786  # William Brydone Jack Observatory N.H.S.
    set_key CA-5237 VEFF-1271  # Ganong Nature Park
    set_key CA-5238 VEFF-1764  # Belmont House / R. Wilmot Home N.H.S.
    set_key CA-5239 VEFF-1767  # Charlotte County Court House N.H.S.
    set_key CA-5240 VEFF-1769  # Fort Charnisay National Historic Site
    set_key CA-5241 VEFF-1772  # Fort Jemseg National Historic Site
    set_key CA-5242 VEFF-1773  # Fort La Tour National Historic Site
    set_key CA-5243 VEFF-1774  # Fort Nashwaak (Naxoat) National Historic Site
    set_key CA-5244 VEFF-1776  # Fredericton City Hall National Historic Site
    set_key CA-5245 VEFF-1777  # Hartland Covered Bridge National Historic Site
    set_key CA-5246 VEFF-1780  # Loyalist House National Historic Site
    set_key CA-5247 VEFF-1781  # Meductic Indian Village / Fort Meducti N.H.S.
    set_key CA-5248 VEFF-1784  # York County Court House National Historical Site
    set_key CA-5249 VEFF-2244  # Blackville Municipal Park
    set_key CA-5250 VEFF-2245  # Bore View Park
    set_key CA-5251 VEFF-2247  # Burpee Bar Nature Preserve
    set_key CA-5252 VEFF-2248  # Burton Park
    set_key CA-5253 VEFF-2249  # Carleton Park
    set_key CA-5255 VEFF-2251  # Ecological Park of the Acadian Peninsula
    set_key CA-5258 VEFF-2256  # Killarney Lake Park
    set_key CA-5259 VEFF-2257  # Kings Landing Historic Settlement National Historical Site
    set_key CA-5260 VEFF-2258  # Lepreau Falls Natural Area
    set_key CA-5261 VEFF-2262  # Mapleton Park
    set_key CA-5262 VEFF-2263  # Metepenagiag Heritage Park
    set_key CA-5263 VEFF-2264  # Mill Creek Nature Park
    set_key CA-5264 VEFF-2265  # O'Connell Park
    set_key CA-5265 VEFF-2268  # Princess Louise Park
    set_key CA-5266 VEFF-2269  # Riverfront Park
    set_key CA-5267 VEFF-2270  # Rotary Memorial Park
    set_key CA-5268 VEFF-2271  # Rotary Nature Park
    set_key CA-5269 VEFF-2273  # St. Anne's Chapel of Ease National Historic Site
    set_key CA-5270 VEFF-2274  # St. John's Anglican Church / Stone Church N.H.S.
    set_key CA-5271 VEFF-2277  # Sussex Nature Walkway Conservation Area
    set_key CA-5272 VEFF-2278  # Utopia Wildlife Refuge
    set_key CA-5273 VEFF-2279  # Wilmot Park
    set_key CA-5274 VEFF-2280  # Wolastoq Park (Wolastoq) National Historic Site
    set_key CA-5275 VEFF-2788  # Discovery Geopark Geopark
    set_key CA-5276 VEFF-2789  # Fleur de Lys Soapstone Quarries N.H.S.
    set_key CA-5277 VEFF-2791  # Harbour Grace Court House National Historic Site
    set_key CA-5278 VEFF-2793  # Indian Point National Historic Site
    set_key CA-5279 VEFF-2797  # Murray Premises National Historic Site
    set_key CA-5280 VEFF-2798  # Okak National Historic Site
    set_key CA-5281 VEFF-2799  # Port Union Historic District National Historic Site
    set_key CA-5282 VEFF-2800  # Rennies Mill Road Historic District N.H.S.
    set_key CA-5283 VEFF-2801  # Watts Point Ecological Reserve
    set_key CA-5284 VEFF-2282  # Basilica of St. John the Baptist N.H.S.
    set_key CA-5285 VEFF-2804  # Kodlunarn Island National Historical Site
    set_key CA-5286 VEFF-2807  # Canadian Bank of Commerce National Historic Site
    set_key CA-5287 VEFF-2815  # Tr'ochek National Historic Site
    set_key CA-5288 VEFF-2820  # Covehead Harbour National Historic Site
    set_key CA-5289 VEFF-2825  # Kent G Ellis Heritage Park
    set_key CA-5290 VEFF-1332  # Amherstburg First Baptist Church N.H.S.
    set_key CA-5291 VEFF-3554  # Ken Reid Conservation Area
    set_key CA-5292 VEFF-1333  # Amherstburg Navy Yard National Historic Site
    set_key CA-5293 VEFF-1334  # Ann Baillie Building National Historic Site
    set_key CA-5294 VEFF-1335  # Banting House National Historic Site
    set_key CA-5295 VEFF-1339  # Baxter Conservation Area
    set_key CA-5296 VEFF-1340  # Bead Hill National Historic Site
    set_key CA-5297 VEFF-1342  # Bell Homestead National Historic Site
    set_key CA-5298 VEFF-1343  # Belleville Railway Station (Grand Trunk) N.H.S.
    set_key CA-5299 VEFF-1346  # Buxton Settlement National Historic Site
    set_key CA-5300 VEFF-1348  # Cataraqui Cemetery National Historic Site
    set_key CA-5301 VEFF-1350  # David Dunlap Observatory National Historic Site
    set_key CA-5302 VEFF-1353  # Fort Erie National Historic Site
    set_key CA-5303 VEFF-1354  # Fort Frontenac National Historic Site
    set_key CA-5304 VEFF-1361  # Fort York National Historic Site
    set_key CA-5305 VEFF-1362  # Frontenac County Court National Historic Site
    set_key CA-5306 VEFF-1363  # Fulford Place National Historic Site
    set_key CA-5307 VEFF-1371  # Hiawatha Highlands Conservation Area
    set_key CA-5308 VEFF-1374  # Hough House National Historic Site
    set_key CA-5309 VEFF-1376  # Kensington Market National Historic Site
    set_key CA-5310 VEFF-1380  # McCrae House National Historic Site
    set_key CA-5311 VEFF-1381  # Middlesex County Court House N.H.S.
    set_key CA-5312 VEFF-1385  # Nottawasaga Bluffs Conservation Area
    set_key CA-5313 VEFF-1401  # Tiffin Centre Conservation Area
    set_key CA-5314 VEFF-1402  # Tottenham Conservation Area
    set_key CA-5315 VEFF-1403  # Utopia Conservation Area
    set_key CA-5316 VEFF-1409  # Wolseley Barracks National Historic Site
    set_key CA-5317 VEFF-3651  # Rockwood Conservation Area
    set_key CA-5318 VEFF-3527  # Guelph Lake Conservation Area
    set_key CA-5319 VEFF-3438  # Belwood Lake Conservation Area
    set_key CA-5320 VEFF-1616  # Britannia Shipyard National Historic Site
    set_key CA-5322 VEFF-1612  # Benvoulin Heritage Park
    set_key CA-5323 VEFF-1622  # Central Community Park
    set_key CA-5324 VEFF-1643  # Fairfield Park
    set_key CA-5325 VEFF-1645  # Fort Hope National Historic Site
    set_key CA-5326 VEFF-1660  # Hatley Park National Historic Site
    set_key CA-5327 VEFF-1665  # Island 22 Regional Park
    set_key CA-5329 VEFF-1670  # Johns Family Nature Conservancy
    set_key CA-5330 VEFF-1673  # Kaloya Regional Park
    set_key CA-5331 VEFF-1676  # Kelowna City Park
    set_key CA-5334 VEFF-1696  # McKinley Landing Park
    set_key CA-5335 VEFF-1697  # McKinley Mountain Park
    set_key CA-5337 VEFF-1700  # Mission Creek Regional Park
    set_key CA-5338 VEFF-1712  # Paul's Tomb Recreation Park
    set_key CA-5339 VEFF-1715  # Quail Ridge Linear Park
    set_key CA-5341 VEFF-1724  # Rotary Beach Park
    set_key CA-5343 VEFF-1732  # Skaha Lake Park
    set_key CA-5344 VEFF-1739  # Stephens Coyote Ridge Regional Park
    set_key CA-5345 VEFF-1745  # Swalwell Park
    set_key CA-5346 VEFF-1749  # Thompson Regional Park
    set_key CA-5347 VEFF-1750  # Thomson Marsh Park
    set_key CA-5349 VEFF-1658  # Gwynne Vaughan Park Conservation Area
    set_key CA-5350 VEFF-2196  # Tumbler Ridge UNESCO Global Geopark
    set_key CA-5351 VEFF-1926  # Battle of Stoney Creek National Historic Site
    set_key CA-5352 VEFF-1927  # Backus Woods Forest Reserve
    set_key CA-5353 VEFF-1928  # Belfountain Conservation Area
    set_key CA-5354 VEFF-1930  # Burlington Heights National Historic Site
    set_key CA-5355 VEFF-1931  # Christie Lake Conservation Area
    set_key CA-5356 VEFF-1933  # Confederation Beach Park
    set_key CA-5357 VEFF-1936  # Crooks Hollow Conservation Area
    set_key CA-5358 VEFF-1937  # Devil's Punch Bowl Conservation Area
    set_key CA-5359 VEFF-1938  # Dundas Valley Conservation Area
    set_key CA-5360 VEFF-1939  # Dundurn Castle National Historic Site
    set_key CA-5361 VEFF-1940  # Eramosa Karst Conservation Area
    set_key CA-5362 VEFF-1942  # Fifty Point Conservation Area
    set_key CA-5363 VEFF-1943  # Fletcher Creek Ecological Reserve
    set_key CA-5364 VEFF-1944  # Griffin House National Historic Site
    set_key CA-5365 VEFF-1945  # Hamilton Waterworks National Historic Site
    set_key CA-5366 VEFF-1947  # Island Lake Conservation Area
    set_key CA-5367 VEFF-1948  # McQuesten House / Whitehern National Historic Site
    set_key CA-5368 VEFF-1949  # Meadowvale Conservation Area
    set_key CA-5369 VEFF-1951  # Mowhawk Chapel National Historic Site
    set_key CA-5370 VEFF-1952  # Rattray Marsh Conservation Area
    set_key CA-5371 VEFF-1953  # Royal Botanical Gardens National Historic Site
    set_key CA-5372 VEFF-1955  # Silver Creek Conservation Area
    set_key CA-5373 VEFF-1957  # Terra Cotta Conservation Area
    set_key CA-5374 VEFF-1959  # Upper Credit Conservation Area
    set_key CA-5375 VEFF-1960  # Valens Lake Conservation Area
    set_key CA-5376 VEFF-1587  # Beaver Hills Biosphere Reserve
    set_key CA-5377 VEFF-1607  # Nordegg National Historic Site
    set_key CA-5378 VEFF-1302  # Chamberlains Park
    set_key CA-5380 VEFF-1317  # Topsail Beach Rotary Park
    set_key CA-5381 VEFF-1318  # Voisey's Brook Park
    set_key CA-5382 VEFF-1321  # Worsley Park
    set_key CA-5383 VEFF-1785  # Cape Pine Lighthouse National Historic Site
    set_key CA-5384 VEFF-1788  # Colony of Avalon National Historic Site
    set_key CA-5385 VEFF-1789  # Fort Townshend National Historic Site
    set_key CA-5386 VEFF-1790  # Government House National Historic Site
    set_key CA-5387 VEFF-1792  # Hebron Mission National Historic Site
    set_key CA-5388 VEFF-1796  # Mallard Cottage National Historic Site
    set_key CA-5389 VEFF-1801  # St. John the Baptist Anglican Cathedral N.H.S.
    set_key CA-5390 VEFF-1802  # St. John's Court House National Historic Site
    set_key CA-5391 VEFF-1803  # St. Thomas Rectory / Commissariat House and Garden N.H.S.
    set_key CA-5392 VEFF-1804  # Tilting National Historic Site
    set_key CA-5393 VEFF-2283  # Battle Harbour Historic District N.H.S.
    set_key CA-5394 VEFF-2285  # Boyd's Cove Beothuk National Historic Site
    set_key CA-5395 VEFF-2286  # Cable Building National Historic Site
    set_key CA-5396 VEFF-2287  # Cape Race Lighthouse National Historic Site
    set_key CA-5397 VEFF-2288  # Christ Church / Quidi Vidi Church N.H.S.
    set_key CA-5399 VEFF-2290  # Former Bank of British North America N.H.S.
    set_key CA-5400 VEFF-2291  # Former Carbonear Railway Station (Newfoundland Railway) N.H.S.
    set_key CA-5401 VEFF-2292  # Former Newfoundland Railway Headquarters N.H.S.
    set_key CA-5402 VEFF-2293  # Fort Amherst National Historic Site
    set_key CA-5403 VEFF-2294  # Fort William National Historic Site
    set_key CA-5404 VEFF-2298  # St. Patrick's Roman Catholic Church N.H.S.
    set_key CA-5405 VEFF-2300  # Water Street Historic District National Historical Site
    set_key CA-5406 VEFF-2301  # Winterholme National Historic Site
    set_key CA-5407 VEFF-1805  # Alberton Court House National Historic Site
    set_key CA-5409 VEFF-1807  # Apothecaries Hall National Historic Site
    set_key CA-5410 VEFF-1811  # Charlottetown City Hall National Historic Site
    set_key CA-5411 VEFF-1812  # Confederation Centre of the Arts N.H.S.
    set_key CA-5412 VEFF-1815  # Dundas Terrace National Historic Site
    set_key CA-5413 VEFF-1816  # Fairholm National Historic Site
    set_key CA-5414 VEFF-1817  # Farmers' Bank of Rustico National Historic Site
    set_key CA-5415 VEFF-1818  # Former Summerside Post Office N.H.S.
    set_key CA-5416 VEFF-1819  # Government House National Historic Site
    set_key CA-5417 VEFF-1820  # Great George Street Historic District N.H.S.
    set_key CA-5418 VEFF-1821  # Jean-Pierre Roma at Three Rivers, P.E.I. N.H.S.
    set_key CA-5419 VEFF-1822  # Kensington Railway Station N.H.S.
    set_key CA-5420 VEFF-1826  # Shaw's Hotel National Historic Site
    set_key CA-5421 VEFF-1828  # St. Dunstan's Roman Catholic Basilica N.H.S.
    set_key CA-5422 VEFF-2326  # Harvey Moore Wildlife Management Area
    set_key CA-5424 VEFF-1833  # Acacia Grove / Prescott House N.H.S.
    set_key CA-5425 VEFF-1834  # Admiralty House National Historic Site
    set_key CA-5426 VEFF-1847  # Cole Harbour-Lawrencetown Coastal Heritage Park
    set_key CA-5427 VEFF-1855  # Halifax City Hall National Historic Site
    set_key CA-5428 VEFF-1856  # Halifax Public Gardens National Historic Site
    set_key CA-5430 VEFF-1866  # Pier 21 National Historic Site
    set_key CA-5431 VEFF-1870  # Springhill Coal Mining National Historic Site
    set_key CA-5432 VEFF-1871  # S.S. Acadia National Historic Site
    set_key CA-5434 VEFF-2333  # Anthony Provincial Park
    set_key CA-5435 VEFF-2336  # Cliffs of Fundy Geopark
    set_key CA-5436 VEFF-2337  # Coldbrook Provincial Park
    set_key CA-5438 VEFF-2341  # Fort St. Louis National Historic Site
    set_key CA-5439 VEFF-2342  # Groves Point Provincial Park
    set_key CA-5441 VEFF-2345  # Lake-O-Law Provincial Park
    set_key CA-5443 VEFF-2348  # Membertou Heritage Park National Historical Park
    set_key CA-5444 VEFF-2350  # Ovens Natural Park Nature Park
    set_key CA-5445 VEFF-2354  # Pondville Beach Provincial Park
    set_key CA-5446 VEFF-2356  # Ross Ferry Provincial Park
    set_key CA-5448 VEFF-2358  # Thinkers Lodge National Historic Site
    set_key CA-5449 VEFF-1411  # Aishihik Lake Recreation Site
    set_key CA-5451 VEFF-1420  # Lapierre House (Zheh Gwatsal [small house]) Nature Reserve
    set_key CA-5452 VEFF-1426  # Simpson Lake Recreation Park
    set_key CA-5453 VEFF-1429  # Teslin Lake Recreation Park
    set_key CA-5454 VEFF-2312  # Discovery Claim (Claim 37903) National Historic Site
    set_key CA-5455 VEFF-2318  # Old Territorial Administration Building N.H.S.
    set_key CA-5456 VEFF-2319  # St. Paul's Anglican Church N.H.S.
    set_key CA-5458 VEFF-2321  # Yukon Hotel National Historic Site
    set_key CA-5459 VEFF-1571  # Holy Trinity Anglican Church Provincial Historic Site
    set_key CA-5460 VEFF-1574  # Marr Residence National Historic Site
    set_key CA-5461 VEFF-1969  # Montgomery Place National Historic Site
    set_key CA-5462 VEFF-1970  # Moose Jaw Court House National Historic Site
    set_key CA-5463 VEFF-1973  # Next of Kin Memorial Avenue N.H.S.
    set_key CA-5464 VEFF-1547  # Netley-Libau Marsh Bird Sanctuary
    set_key CA-5465 VEFF-1553  # Tall Grass Prairie Preserve
    set_key CA-5466 VEFF-2303  # Blacklead Island Whaling Station N.H.S.
    set_key CA-5467 VEFF-2304  # Bloody Falls National Historic Site
    set_key CA-5468 VEFF-2308  # Inuksuk National Historic Site
    set_key CA-5469 VEFF-2309  # Port Refuge National Historic Site
    set_key CA-5470 VEFF-2218  # Church of Our Lady of Good Hope N.H.S.
    set_key CA-5471 VEFF-2219  # Deline Fishery / Franklin's Fort N.H.S.
    set_key CA-5472 VEFF-2221  # Ehdaa National Historic Site
    set_key CA-5473 VEFF-2222  # Fort McPherson National Historic Site
    set_key CA-5474 VEFF-2224  # Fort Reliance National Historic Site
    set_key CA-5475 VEFF-2225  # Fort Resolution National Historic Site
    set_key CA-5476 VEFF-2228  # Hay River Mission Sites National Historic Site
    set_key CA-5477 VEFF-2232  # Kittigazuit Archaeological Sites N.H.S.
    set_key CA-5478 VEFF-2235  # Nagwichoonjik (Mackenzie River) N.H.S.
    set_key CA-5479 VEFF-2237  # Parry's Rock Wintering Site N.H.S.
    set_key CA-5480 VEFF-2240  # Tsa Tue Biosphere Reserve
    set_key CA-5495 VEFF-3369  # Swissair Memorial Site (Bayswater) Provincial Park
    set_key CA-5496 VEFF-4472  # Aldergrove Regional Park
    set_key CA-5497 VEFF-4479  # Boundary Bay Regional Park
    set_key CA-5498 VEFF-4486  # Capilano River Regional Park
    set_key CA-5500 VEFF-4490  # Deas Island Regional Park
    set_key CA-5501 VEFF-4503  # Grouse Mountain Regional Park
    set_key CA-5502 VEFF-3159  # Iona Beach Regional Park
    set_key CA-5504 VEFF-4511  # Minnekhada Regional Park
    set_key CA-5508 VEFF-3647  # Robert Edmondson Conservation Area
    set_key CA-5518 VEFF-4468  # Highwood River Natural Area
    set_key CA-5532 VEFF-4469  # Kitaskino Nuwenëné Wildland Provincial Park
    set_key CA-5533 VEFF-4270  # Kootenay Plains Provincial Recreation Area
    set_key CA-5535 VEFF-2960  # Airmen's Park National Historic Site
    set_key CA-5537 VEFF-3355  # Lock 5 Park National Historic Site
    set_key CA-5538 VEFF-3549  # J. Henry Tweed Conservation Area
    set_key CA-5539 VEFF-3772  # Uplands Park Natural Area
    set_key CA-5540 VEFF-3749  # Beacon Hill Natural Area
    set_key CA-5541 VEFF-3495  # E.M. Warwick Conservation Area
    set_key CA-5542 VEFF-2972  # Foley Mountain Conservation Area
    set_key CA-5543 VEFF-2985  # Morris Island Conservation Area
    set_key CA-5545 VEFF-3812  # Trinity Royal Heritage Conservation Area
    set_key CA-5552 VEFF-3447  # Bolton Resource Management Tract Conservation Area
    set_key CA-5554 VEFF-2965  # Boyd Conservation Park
    set_key CA-5555 VEFF-2966  # Boyd North Conservation Area
    set_key CA-5556 VEFF-3516  # Glassco Park Conservation Area
    set_key CA-5557 VEFF-3496  # East Duffins Headwaters Conservation Area
    set_key CA-5558 VEFF-2977  # Kortright Centre for Conservation
    set_key CA-5559 VEFF-3691  # Tommy Thompson Park
    set_key CA-5560 VEFF-3714  # West Duffins Headwaters Conservation Area
    set_key CA-5562 VEFF-3555  # Ken Whillans Resource Recreation Park
    set_key CA-5563 VEFF-3574  # Limehouse Conservation Area
    set_key CA-5564 VEFF-4355  # Area 8 Conservation Area
    set_key CA-5565 VEFF-4380  # Dofasco 2000 Trail
    set_key CA-5566 VEFF-4420  # Saltfleet Conservation Area
    set_key CA-5567 VEFF-4374  # Canal Park (Desjardins)
    set_key CA-5568 VEFF-4409  # Mount Albion Conservation Area
    set_key CA-5570 VEFF-4440  # Westfield Heritage Village Conservation Area
    set_key CA-5571 VEFF-3442  # Binbrook Conservation Area
    set_key CA-5572 VEFF-3724  # Woolverton Conservation Area
    set_key CA-5573 VEFF-3612  # Mountainview Conservation Area
    set_key CA-5575 VEFF-3552  # Jordan Harbour Conservation Area
    set_key CA-5576 VEFF-3700  # Virgil (Lower Virgil) Conservation Area
    set_key CA-5577 VEFF-3696  # Two Mile Creek Conservation Area
    set_key CA-5578 VEFF-3723  # Woodend Conservation Area
    set_key CA-5580 VEFF-3533  # Hedley Forest Conservation Area
    set_key CA-5581 VEFF-3654  # Ruigrok Tract Conservation Area
    set_key CA-5582 VEFF-3456  # Canborough Conservation Area
    set_key CA-5583 VEFF-4414  # Port Davidson Conservation Area
    set_key CA-5585 VEFF-3463  # Chippawa Creek Conservation Area
    set_key CA-5586 VEFF-3511  # Gainsborough Conservation Area
    set_key CA-5587 VEFF-3470  # Comfort Maple Conservation Area
    set_key CA-5588 VEFF-3676  # St. Johns Conservation Area
    set_key CA-5589 VEFF-3493  # E.C. Brown Conservation Area
    set_key CA-5590 VEFF-3719  # Willoughby Marsh Conservation Area
    set_key CA-5591 VEFF-3679  # Stevensville Conservation Area
    set_key CA-5592 VEFF-3544  # Humberstone Marsh Conservation Area
    set_key CA-5593 VEFF-3704  # Wainfleet Wetlands Conservation Area
    set_key CA-5594 VEFF-3608  # Morgan's Point Conservation Area
    set_key CA-5596 VEFF-3578  # Long Beach Conservation Area
    set_key CA-5597 VEFF-3448  # Brant Conservation Area
    set_key CA-5598 VEFF-3451  # Byng Island Conservation Area
    set_key CA-5599 VEFF-3471  # Conestogo Lake Conservation Area
    set_key CA-5600 VEFF-3499  # Elora Quarry Conservation Area
    set_key CA-5601 VEFF-3568  # Laurel Creek Conservation Area
    set_key CA-5603 VEFF-3630  # Pinehurst Lake Conservation Area
    set_key CA-5604 VEFF-3660  # Shade's Mills Conservation Area
    set_key CA-5605 VEFF-4083  # FWR Dickson Wilderness Area
    set_key CA-5607 VEFF-3677  # Starkey Hill Conservation Area
    set_key CA-5608 VEFF-3686  # Taquanyah Conservation Area
    set_key CA-5609 VEFF-3670  # Snyder's Flats Conservation Area
    set_key CA-5611 VEFF-3433  # Backus Heritage Conservation Area
    set_key CA-5612 VEFF-3481  # Deer Creek Conservation Area
    set_key CA-5614 VEFF-3616  # Norfolk Conservation Area
    set_key CA-5616 VEFF-4392  # Hawkins Tract Conservation Area
    set_key CA-5617 VEFF-3455  # Calton Swamp Wetland Complex Wildlife Management Area
    set_key CA-5618 VEFF-3430  # Archie Coulter Conservation Area
    set_key CA-5619 VEFF-3673  # Springwater Conservation Area
    set_key CA-5620 VEFF-3725  # Yarmouth Natural Heritage Area Conservation Area
    set_key CA-5621 VEFF-3479  # Dalewood Conservation Area
    set_key CA-5622 VEFF-3565  # Lake Whittaker Conservation Area
    set_key CA-5623 VEFF-3480  # Dan Patterson Conservation Area
    set_key CA-5627 VEFF-3548  # Inglis Falls Conservation Area
    set_key CA-5632 VEFF-2969  # Cobourg Conservation Area
    set_key CA-5634 VEFF-3539  # Highland Glen Conservation Area
    set_key CA-5635 VEFF-3579  # Long Sault Conservation Area
    set_key CA-5637 VEFF-3521  # Goodrich-Loomis Conservation Area
    set_key CA-5638 VEFF-3512  # Ganaraska Forest Conservation Area
    set_key CA-5640 VEFF-3678  # Stephen's Gulch Conservation Area
    set_key CA-5641 VEFF-2994  # Sylvan Glen Conservation Area
    set_key CA-5642 VEFF-4952  # Rock Dunder Nature Reserve
    set_key CA-5643 VEFF-3462  # Charles Sauriol Conservation Area
    set_key CA-5645 VEFF-3436  # Ball's Mill Conservation Area
    set_key CA-5646 VEFF-2973  # Ganaraska Millennium Conservation Area
    set_key CA-5647 VEFF-4417  # Rice Lake Conservation Area
    set_key CA-5648 VEFF-3514  # Garden Hill Conservation Area
    set_key CA-5649 VEFF-3644  # Richardson's Lookout Conservation Area
    set_key CA-5650 VEFF-3690  # Thurne Parks Conservation Area
    set_key CA-5651 VEFF-3536  # Hibou Conservation Area
    set_key CA-5652 VEFF-2988  # Port Hope Conservation Area
    set_key CA-5653 VEFF-3634  # Pottawatomi and Jones Falls Conservation Area
    set_key CA-5654 VEFF-3620  # Old Baldy Conservation Area
    set_key CA-5655 VEFF-3547  # Indian Falls Conservation Area
    set_key CA-5656 VEFF-3502  # Eugenia Falls Conservation Area
    set_key CA-5657 VEFF-3500  # Epping-John Muir Lookout Conservation Area
    set_key CA-5658 VEFF-3672  # Spirit Rock &amp; McNeill Estate Conservation Area
    set_key CA-5659 VEFF-3446  # Bognor-Marsh Management Area
    set_key CA-5660 VEFF-3431  # Arran Lake Conservation Area
    set_key CA-5661 VEFF-3506  # Feversham Gorge &amp; Madeleine Graydon Memorial Conservation Area
    set_key CA-5662 VEFF-4354  # Arboretum (Grey Sauble Conservation)
    set_key CA-5663 VEFF-3534  # Hepworth Management Area
    set_key CA-5664 VEFF-4405  # Massie Hills Management Area
    set_key CA-5665 VEFF-4434  # The Glen Management Area
    set_key CA-5666 VEFF-3441  # Bighead River Management Area
    set_key CA-5668 VEFF-3752  # Elk/Beaver Lake Regional Park
    set_key CA-5669 VEFF-3540  # Holiday Beach Conservation Area
    set_key CA-5671 VEFF-4121  # Wilket Creek Park
    set_key CA-5672 VEFF-3201  # Bi-Centennial Park Recreation Park
    set_key CA-5673 VEFF-3202  # Centennial Park (St. Andrews) Recreation Park
    set_key CA-5674 VEFF-3203  # Chatham Waterfront Trail
    set_key CA-5675 VEFF-3204  # Chown Field Recreation Park
    set_key CA-5676 VEFF-3205  # Coronation Park (Oromocto) Recreation Park
    set_key CA-5677 VEFF-3206  # David Alison Ganong Chocolate Park
    set_key CA-5678 VEFF-3207  # Deer Park
    set_key CA-5686 VEFF-3216  # Gondola Point Beach Recreation Park
    set_key CA-5687 VEFF-3217  # Harriet Irving Memorial Park
    set_key CA-5688 VEFF-3219  # Hillside Trail National Scenic Trail
    set_key CA-5690 VEFF-3221  # Indian Point Park
    set_key CA-5691 VEFF-3222  # Jervis Bay-Ross Memorial Park Memorial Parkway
    set_key CA-5693 VEFF-3224  # King's Square National Historic Site
    set_key CA-5694 VEFF-3225  # King Square West Recreation Park
    set_key CA-5696 VEFF-3227  # Langmaid Park Recreation Park
    set_key CA-5697 VEFF-3228  # Larche Memorial Parkway
    set_key CA-5699 VEFF-3230  # Loyalists Burial Ground (Beaver Fountain) Recreation Park
    set_key CA-5701 VEFF-3232  # Matthew's Brook Trail
    set_key CA-5702 VEFF-3233  # Matthew's Cove Park
    set_key CA-5703 VEFF-3234  # Meenan's Cove Park
    set_key CA-5704 VEFF-3235  # Mispec Park Recreation Park
    set_key CA-5706 VEFF-3237  # Pines Conservation Park
    set_key CA-5707 VEFF-3238  # Pte. David Robert Greenslade Peace Park
    set_key CA-5708 VEFF-3239  # Public Gardens (Saint John) Recreation Park
    set_key CA-5709 VEFF-3240  # QPlex Recreation Park
    set_key CA-5711 VEFF-3242  # Queen Square (St. John) Recreation Park
    set_key CA-5713 VEFF-3244  # Queen Square West Recreation Park
    set_key CA-5714 VEFF-3245  # Quispamsis Arts &amp; Culture Park
    set_key CA-5717 VEFF-3248  # Renforth Rotary Park
    set_key CA-5718 VEFF-3249  # Ritchie Lake Park
    set_key CA-5721 VEFF-3252  # Rothesay Common Recreation Park
    set_key CA-5722 VEFF-3253  # Saunder's Brook Trail
    set_key CA-5724 VEFF-3255  # Shamrock Park
    set_key CA-5725 VEFF-3257  # Steele-Kennedy Nature Park
    set_key CA-5726 VEFF-3259  # Trinity Church and Rectory National Historic Site
    set_key CA-5727 VEFF-3260  # Tucker Park
    set_key CA-5728 VEFF-3261  # Victoria Square Park
    set_key CA-5729 VEFF-3262  # Village Historique Acadien National Historical Site
    set_key CA-5730 VEFF-3263  # Waterford Green Recreation Park
    set_key CA-5731 VEFF-3264  # Wells Recreation Park
    set_key CA-5732 VEFF-3265  # Bannerman Park
    set_key CA-5734 VEFF-3267  # Victoria Park
    set_key CA-5735 VEFF-3268  # Arvia'juaq and Qikiqtaarjuk National Historic Site
    set_key CA-5736 VEFF-3269  # Fall Caribou Crossing National Historic Site
    set_key CA-5737 VEFF-3270  # Big Creek Recreation Park
    set_key CA-5738 VEFF-3271  # Lake Laberge Recreation Park
    set_key CA-5739 VEFF-3272  # Lucky Lake Recreation Site
    set_key CA-5740 VEFF-3273  # Robert Service Recreation Park
    set_key CA-5742 VEFF-3275  # Shipyards Park
    set_key CA-5743 VEFF-3276  # Twin Lakes Recreation Park
    set_key CA-5744 VEFF-3277  # Watson Lake Recreation Park
    set_key CA-5745 VEFF-3278  # Wolf Creek Recreation Park
    set_key CA-5746 VEFF-3279  # Wye Lake Park
    set_key CA-5747 VEFF-3280  # A.A. MacDonald Memorial Gardens
    set_key CA-5750 VEFF-3283  # Bridge Park
    set_key CA-5751 VEFF-3284  # Brighton Beach Front Range National Heritage Site
    set_key CA-5753 VEFF-3286  # Cape Bear National Heritage Site
    set_key CA-5754 VEFF-3287  # Cape Bear Natural Area
    set_key CA-5755 VEFF-3288  # Cape Tryon National Heritage Site
    set_key CA-5759 VEFF-3293  # Fullerton's Creek Conservation Park
    set_key CA-5760 VEFF-3294  # Gateway Park (Reg Rodgers) Recreation Park
    set_key CA-5761 VEFF-3295  # Georgetown West Street Beach Recreation Park
    set_key CA-5762 VEFF-3296  # Hyde Park
    set_key CA-5764 VEFF-3298  # Ferry Road Park
    set_key CA-5765 VEFF-3299  # Harvard Street Park
    set_key CA-5766 VEFF-3300  # Heather Moyse Heritage Park
    set_key CA-5768 VEFF-3303  # Keppoch Park
    set_key CA-5769 VEFF-3304  # Kinlock Park
    set_key CA-5770 VEFF-3305  # Lantz Park
    set_key CA-5771 VEFF-3306  # Lowther Park
    set_key CA-5772 VEFF-3307  # MacKinley Park
    set_key CA-5773 VEFF-3309  # MacNeill Park
    set_key CA-5774 VEFF-3310  # MacPhail Park
    set_key CA-5775 VEFF-3311  # Marine Rail National Historical Park
    set_key CA-5776 VEFF-3312  # Northport Rear Range National Heritage Site
    set_key CA-5777 VEFF-3313  # Panmure Head National Heritage Site
    set_key CA-5778 VEFF-3314  # Penzie Lane Park
    set_key CA-5779 VEFF-3315  # Point Prim Recreation Park
    set_key CA-5780 VEFF-3316  # Pondside Park
    set_key CA-5782 VEFF-3318  # Primrose Park
    set_key CA-5783 VEFF-3319  # Queen Elizabeth Park
    set_key CA-5784 VEFF-3320  # Rankin Park
    set_key CA-5786 VEFF-3322  # Robert L. Cotton Park
    set_key CA-5788 VEFF-3324  # Rotrary Friendship Park
    set_key CA-5790 VEFF-3326  # Schurman Park
    set_key CA-5791 VEFF-3327  # Sir Andrew MacPhail Homestead National Historic Site
    set_key CA-5792 VEFF-3328  # Centennial Park (Summerside) Recreation Park
    set_key CA-5794 VEFF-3330  # Veterans Memorial Park
    set_key CA-5796 VEFF-2832  # Africville National Historic Site
    set_key CA-5797 VEFF-2833  # Akins House National Historic Site
    set_key CA-5798 VEFF-2834  # Annapolis County Court House National Historic Site
    set_key CA-5799 VEFF-2835  # Annapolis Royal Historic District National Heritage Site
    set_key CA-5800 VEFF-2836  # Antigonish County Court House National Historic Site
    set_key CA-5801 VEFF-2837  # Argyle Township Court House and Gaol National Historic Site
    set_key CA-5802 VEFF-2838  # Black-Binney House National Historic Site
    set_key CA-5803 VEFF-2839  # Cast Iron Fa?ade / Coomb's Old English Shoe Store National Historic Site
    set_key CA-5804 VEFF-2840  # Chapel Island National Historic Site
    set_key CA-5805 VEFF-2841  # Chapman House National Historic Site
    set_key CA-5806 VEFF-2842  # Covenanter Church National Historic Site
    set_key CA-5807 VEFF-2843  # Debert Palaeo-Indian Site National Historic Site
    set_key CA-5808 VEFF-2844  # Enragee Point National Heritage Site
    set_key CA-5809 VEFF-2845  # Fernwood National Historic Site
    set_key CA-5810 VEFF-2846  # Five Islands Lighthouse Park National Heritage Area
    set_key CA-5811 VEFF-2847  # Fort Needham Memorial Park National Historic Site
    set_key CA-5812 VEFF-2848  # Government House (Halifax) National Historic Site
    set_key CA-5813 VEFF-2849  # Grand-Pre Rural Historic District National Historic Site
    set_key CA-5814 VEFF-2850  # Granville Block National Historic Site
    set_key CA-5815 VEFF-2851  # Halifax Court House National Historic Site
    set_key CA-5816 VEFF-2852  # Halifax Dockyard National Historic Site
    set_key CA-5817 VEFF-2853  # Halifax Drill Hall National Historic Site
    set_key CA-5818 VEFF-2854  # Halifax Waterfront Buildings National Historic Site
    set_key CA-5819 VEFF-2855  # Halifax WWII Coastal Defences National Historic Site
    set_key CA-5820 VEFF-2856  # Henry House National Historic Site
    set_key CA-5821 VEFF-2857  # HMCS Sackville National Historic Site
    set_key CA-5822 VEFF-2858  # Hydrostone District National Historic Site
    set_key CA-5823 VEFF-2859  # Jonathan McCully House National Historic Site
    set_key CA-5824 VEFF-2860  # King's College National Historic Site
    set_key CA-5825 VEFF-2861  # Knaut-Rhuland House National Historic Site
    set_key CA-5826 VEFF-2862  # Ladies' Seminary National Historic Site
    set_key CA-5827 VEFF-2863  # Little Dutch (Deutsch) Church National Historic Site
    set_key CA-5828 VEFF-2864  # Liverpool Town Hall National Historic Site
    set_key CA-5829 VEFF-2865  # Lunenburg Academy National Historic Site
    set_key CA-5830 VEFF-2866  # Marconi Wireless Station National Historic Site
    set_key CA-5831 VEFF-2867  # Memorial Tower National Historic Site
    set_key CA-5833 VEFF-2869  # Old Barrington Meeting House National Historic Site
    set_key CA-5834 VEFF-2870  # Old Burying Ground National Historic Site
    set_key CA-5835 VEFF-2871  # Pictou Academy National Historic Site
    set_key CA-5836 VEFF-2872  # Pictou Railway Station (Intercolonial) National Historic Site
    set_key CA-5838 VEFF-2874  # Sainte-Anne / Port Dauphin National Historic Site
    set_key CA-5839 VEFF-2876  # Sinclair Inn / Farmer's Hotel National Historic Site
    set_key CA-5840 VEFF-2877  # Sir Frederick Borden Residence National Historic Site
    set_key CA-5841 VEFF-2878  # St. George's Anglican Church / Round Church National Historic Site
    set_key CA-5842 VEFF-2879  # St. John's Anglican Church National Historic Site
    set_key CA-5843 VEFF-2880  # St. Mary's Basilica National Historic Site
    set_key CA-5844 VEFF-2881  # St. Paul's Anglican Church National Historic Site
    set_key CA-5845 VEFF-2883  # Sydney WWII Coastal Defences National Historic Site
    set_key CA-5846 VEFF-2884  # Trinity Anglican Church National Historic Site
    set_key CA-5847 VEFF-2885  # Truro Post Office National Historic Site
    set_key CA-5849 VEFF-3340  # Bishop Park ( Annapolis Royal) Recreation Park
    set_key CA-5850 VEFF-3336  # Annapolis River Causeway Park
    set_key CA-5851 VEFF-3344  # Delaps Cove Wilderness Trail
    set_key CA-5852 VEFF-2887  # Acton Vale Railway Station (Grand Trunk) National Historic Site
    set_key CA-5853 VEFF-2888  # Alert Hangar National Historic Site
    set_key CA-5854 VEFF-2889  # Apitipik National Historic Site
    set_key CA-5855 VEFF-2890  # Arvida National Historic Site
    set_key CA-5856 VEFF-2891  # Atwater Library of the Mechanics' Institute of Montreal National Historic Site
    set_key CA-5857 VEFF-2892  # Banc de Pêche de Paspébiac N.H.S.
    set_key CA-5858 VEFF-2893  # Bank of Montréal N.H.S.
    set_key CA-5859 VEFF-2894  # Battle of Eccles Hill National Historic Site
    set_key CA-5860 VEFF-2895  # Battle of Lacolle National Historic Site
    set_key CA-5861 VEFF-2896  # Battle of Rivi?re des Prairies / Battle of Coul?e Grou National Historic Site
    set_key CA-5862 VEFF-2897  # Battle of September 6th, 1775 National Historic Site
    set_key CA-5863 VEFF-2898  # Battle of the Lake of Two Mountains National Historic Site
    set_key CA-5864 VEFF-2899  # Beauharnois Power Development National Historic Site
    set_key CA-5865 VEFF-2900  # Belvédère Albert-Gascon
    set_key CA-5866 VEFF-2901  # Beth Israël Cemetery N.H.S.
    set_key CA-5867 VEFF-2902  # Black Watch (Royal Highland Regiment) of Canada Armoury National Historic Site
    set_key CA-5868 VEFF-2903  # Blanc-Sablon National Historic Site
    set_key CA-5869 VEFF-2904  # Bolton-Est Town Hall National Historic Site
    set_key CA-5870 VEFF-2905  # Bon-Pasteur Chapel National Historic Site
    set_key CA-5871 VEFF-2906  # Bonsecours Market National Historic Site
    set_key CA-5872 VEFF-2907  # Cap-des-Rosiers Lighthouse
    set_key CA-5873 VEFF-2908  # Capitol Theatre / Qu?bec Auditorium National Historic Site
    set_key CA-5874 VEFF-2909  # Caughnawaga Mission / Mission of St. Francis Xavier
    set_key CA-5875 VEFF-2910  # Caughnawaga Presbytery National Historic Site
    set_key CA-5876 VEFF-2911  # Chapais House National Historic Site
    set_key CA-5877 VEFF-2912  # Ch?teau De Ramezay / India House National Historic Site
    set_key CA-5878 VEFF-2913  # Christ Church Cathedral National Historic Site
    set_key CA-5879 VEFF-2914  # Church of Notre-Dame-de-la-D?fense National Historic Site
    set_key CA-5880 VEFF-2915  # Church of Notre-Dame-de-la-Pr?sentation National Historic Site
    set_key CA-5881 VEFF-2916  # Church of Saint-L?on-de-Westmount National Historic Site
    set_key CA-5882 VEFF-2917  # Church of Sainte-Marie National Historic Site
    set_key CA-5883 VEFF-2918  # Davie Shipyard National Historic Site
    set_key CA-5884 VEFF-2919  # De Salaberry House National Historic Site
    set_key CA-5885 VEFF-2920  # Droulers-Tsiionhiakwatha National Historic Site
    set_key CA-5886 VEFF-2921  # Erskine and American United Church National Historic Site
    set_key CA-5887 VEFF-2922  # Étienne-Paschal Taché House N.H.S.
    set_key CA-5888 VEFF-2923  # First Geodetic Survey Station National Historic Site
    set_key CA-5889 VEFF-2924  # Former Montr?al Custom House National Historic Site
    set_key CA-5890 VEFF-2925  # Former Shawinigan Aluminum Smelting Complex National Historic Site
    set_key CA-5891 VEFF-2926  # Fort Charlesbourg Royal National Historic Site
    set_key CA-5892 VEFF-2927  # Fort Crevier National Historical Site
    set_key CA-5893 VEFF-2928  # Fort Laprairie National Historic Site
    set_key CA-5894 VEFF-2929  # Fort Longueuil National Historic Site
    set_key CA-5896 VEFF-2931  # Fort Saint-Jean National Historic Site
    set_key CA-5897 VEFF-2932  # Fort St-Louis National Historic Site
    set_key CA-5898 VEFF-2933  # Fort Trois-Rivi?res National Historic Site
    set_key CA-5899 VEFF-2934  # George Stephen House / Mount Stephen Club National Historic Site
    set_key CA-5900 VEFF-2935  # Girardin House National Historic Site
    set_key CA-5902 VEFF-2936  # Parc Aimé-Maillé
    set_key CA-5903 VEFF-2937  # Parc Bourget
    set_key CA-5904 VEFF-2938  # Parc de l'Ecluse
    set_key CA-5905 VEFF-2939  # Parc de l'Île-Perreault
    set_key CA-5906 VEFF-2940  # Parc de la Durantaye
    set_key CA-5907 VEFF-2941  # Parc de la Faune
    set_key CA-5908 VEFF-2942  # Parc de la Promenade
    set_key CA-5909 VEFF-2943  # Parc de la Pulperie
    set_key CA-5910 VEFF-2944  # Parc de la Salette
    set_key CA-5911 VEFF-2945  # Parc des 14 Îles [Parc des Quatorze-Îles]
    set_key CA-5912 VEFF-2946  # Parc des Hauteurs
    set_key CA-5913 VEFF-2947  # Parc des Patriarches
    set_key CA-5914 VEFF-2948  # Parc des Sourires
    set_key CA-5915 VEFF-2949  # Parc Ducharme
    set_key CA-5916 VEFF-2950  # Parc ?cole Pr?vost
    set_key CA-5917 VEFF-2951  # Parc J.-Georges-Dunnigan
    set_key CA-5918 VEFF-2952  # Parc Jacques-Locas
    set_key CA-5919 VEFF-2953  # Parc Lacroix
    set_key CA-5920 VEFF-2954  # Parc Maurice Tessier
    set_key CA-5921 VEFF-2955  # Parc Sandra
    set_key CA-5922 VEFF-2956  # Parc Théobald-Paquette
    set_key CA-5923 VEFF-2957  # Parc Urgel-Carrière
    set_key CA-5924 VEFF-2958  # Pavillon du Lac Bleu
    set_key CA-5925 VEFF-3504  # Falls Reserve Conservation Area
    set_key CA-5929 VEFF-4390  # Hamilton and Scourge Naval Memorial Garden
    set_key CA-5933 VEFF-4463  # Carburn Natural Area
    set_key CA-5936 VEFF-3505  # Fanshawe Conservation Area
    set_key CA-5937 VEFF-3631  # Pittock Conservation Area
    set_key CA-5938 VEFF-3717  # Wildwood Conservation Area
    set_key CA-5939 VEFF-3425  # Réserve naturelle du Boisé-de-la-Marconi
    set_key CA-5940 VEFF-2959  # Aberdeen Pavilion National Historical Site
    set_key CA-5942 VEFF-2964  # Bowmanville Westside Marshes Conservation Area
    set_key CA-5943 VEFF-2967  # Cheltenham Badlands Natural Area
    set_key CA-5944 VEFF-2968  # Chinguacousy Park
    set_key CA-5945 VEFF-3473  # Cooper Marsh Conservation Area
    set_key CA-5947 VEFF-2971  # Devonwood Conservation Area
    set_key CA-5948 VEFF-2974  # Hart Massey House National Historic Site
    set_key CA-5954 VEFF-2982  # Maplelawn&amp;Gardens National Historic Site
    set_key CA-5955 VEFF-2984  # Mill Pond Conservation Area
    set_key CA-5956 VEFF-2987  # Perth Wildlife Reserve
    set_key CA-5957 VEFF-2989  # Portland Bay Conservation Area
    set_key CA-5959 VEFF-3715  # West Rocks Conservation Area
    set_key CA-5960 VEFF-2995  # William T. Foster Woods National Park
    set_key CA-5961 VEFF-2996  # Battle of Seven Oaks National Historic Site
    set_key CA-5962 VEFF-2997  # BCATP Hangar No. 1 National Historic Site
    set_key CA-5963 VEFF-2998  # Bonnycastle Park Historic Site
    set_key CA-5964 VEFF-2999  # Bruce Park Historic Site
    set_key CA-5965 VEFF-3001  # Camp Hughes National Historic Site
    set_key CA-5966 VEFF-3002  # Canadian Pacific Railway Station (Winnipeg) National Historic Site
    set_key CA-5967 VEFF-3003  # Churchill Rocket Research Range National Heritage Site
    set_key CA-5968 VEFF-3004  # Confederation Building National Historic Site
    set_key CA-5969 VEFF-3006  # Dalnavert National Historic Site
    set_key CA-5970 VEFF-3008  # Dominion Exhibition Display Building No. 2 National Historic Site
    set_key CA-5971 VEFF-3009  # Dufferin Park Historic Site
    set_key CA-5972 VEFF-3010  # Early Skyscrapers in Winnipeg National Historic Site
    set_key CA-5973 VEFF-3012  # Exchange District National Historic Site
    set_key CA-5974 VEFF-3013  # First Homestead in Western Canada National Historic Site
    set_key CA-5975 VEFF-3014  # Former Union Bank Building and Annex National Park
    set_key CA-5976 VEFF-3015  # Fort Churchill National Historic Site
    set_key CA-5977 VEFF-3017  # Fort Dufferin National Historic Site
    set_key CA-5978 VEFF-3018  # Fort Garry Hotel National Historic Site
    set_key CA-5979 VEFF-3019  # Fort La Reine National Historic Site
    set_key CA-5980 VEFF-3020  # Grey Nuns' Convent National Historic Site
    set_key CA-5981 VEFF-3428  # Allan Park
    set_key CA-5982 VEFF-3450  # Brucedale Conservation Area
    set_key CA-5983 VEFF-3485  # Denny's Dam
    set_key CA-5984 VEFF-3489  # Durham Conservation Area
    set_key CA-5986 VEFF-3656  # Saugeen Bluffs
    set_key CA-5987 VEFF-3658  # Schmidt Lake
    set_key CA-5988 VEFF-3477  # Crow's Pass
    set_key CA-5989 VEFF-3684  # Sulpher Spring
    set_key CA-5990 VEFF-3699  # Varney Conservation Area
    set_key CA-6003 VEFF-4388  # Great Lakes Waterfront Trail
    set_key CA-6004 VEFF-3464  # Christie Beach Conservation Area
    set_key CA-6006 VEFF-3466  # Clendenan Conservation Area
    set_key CA-6007 VEFF-4376  # Colpoy's Lookout Conservation Area
    set_key CA-6008 VEFF-4399  # Kemble Mountain Conservation Area
    set_key CA-6009 VEFF-3475  # Crediton Conservation Area
    set_key CA-6010 VEFF-3467  # Clinton Conservation Area
    set_key CA-6011 VEFF-3584  # Lucan Conservation Area
    set_key CA-6012 VEFF-3609  # Morrison Dam Conservation Area
    set_key CA-6013 VEFF-3625  # Parkhill Conservation Area
    set_key CA-6014 VEFF-3650  # Rock Glen Conservation Area
    set_key CA-6015 VEFF-3726  # Zurich Conservation Area
    set_key CA-6016 VEFF-3563  # Lake Laurentian Conservation Area
    set_key CA-6017 VEFF-3613  # Mountjoy Historical Conservation Area
    set_key CA-6018 VEFF-3515  # Gillies Lake Conservation Area
    set_key CA-6019 VEFF-3535  # Hersey Lake Conservation Area
    set_key CA-6020 VEFF-3716  # White Waterfront Conservation Area
    set_key CA-6021 VEFF-3022  # Holy Trinity Anglican Church National Historic Site
    set_key CA-6022 VEFF-3023  # Inglis Grain Elevators National Historic Site
    set_key CA-6023 VEFF-3028  # Maison Gabrielle-Roy National Historic Site
    set_key CA-6024 VEFF-3029  # Metropolitan Theatre National Historic Site
    set_key CA-6025 VEFF-3030  # Miami Railway Station (Canadian Northern) National Historic Site
    set_key CA-6026 VEFF-3031  # Miss Davis' School Residence / Twin Oaks National Historic Site
    set_key CA-6027 VEFF-3032  # Neubergthal Street Village National Park
    set_key CA-6028 VEFF-3033  # Norway House National Historic Site
    set_key CA-6029 VEFF-3035  # Pantages Playhouse Theatre National Historic Site
    set_key CA-6030 VEFF-3036  # Portage La Prairie Public Building National Historic Site
    set_key CA-6031 VEFF-3039  # Ralph Connor House National Historic Site
    set_key CA-6032 VEFF-3041  # Red River Floodway National Historic Site
    set_key CA-6033 VEFF-3044  # Roslyn Court Apartments N.H.S.
    set_key CA-6034 VEFF-3045  # Royal Manitoba Theatre Centre National Historic Site
    set_key CA-6035 VEFF-3046  # Sea Horse Gully Remains National Historic Site
    set_key CA-6036 VEFF-3049  # St. Andrew's Anglican Church National Historic Site
    set_key CA-6037 VEFF-3050  # St. Andrews Cam?r? Curtain Bridge Dam National Historic Site
    set_key CA-6038 VEFF-3051  # St. Boniface City Hall National Historic Site
    set_key CA-6039 VEFF-3052  # St. Boniface Hospital Nurses' Residence National Historic Site
    set_key CA-6040 VEFF-3054  # St. Michael's Ukrainian Greek Orthodox Church National Historic Site
    set_key CA-6041 VEFF-3056  # Ukrainian Catholic Church of the Resurrection National Historic Site
    set_key CA-6042 VEFF-3057  # Ukrainian Catholic Church of the Immaculate Conception National Historic Site
    set_key CA-6043 VEFF-3058  # Ukrainian Labour Temple National Historic Site
    set_key CA-6044 VEFF-3059  # Union Station / Winnipeg Railway Station (Canadian National) National Historic Site
    set_key CA-6045 VEFF-3061  # Walker Theatre National Historic Site
    set_key CA-6046 VEFF-3062  # Wasyl Negrych Pioneer Homestead National Historic Site
    set_key CA-6047 VEFF-3064  # William Whyte Park / Fort Douglas Cairn Historic Site
    set_key CA-6048 VEFF-3065  # Winnipeg Law Courts National Historic Site
    set_key CA-6049 VEFF-3066  # Battle of Cut Knife Hill National Historic Site
    set_key CA-6050 VEFF-3067  # Battle of Duck Lake National Historic Site
    set_key CA-6051 VEFF-3068  # Battleford Court House National Historic Site
    set_key CA-6052 VEFF-3071  # Biggar Railway Station (Grand Trunk Pacific) National Historic Site
    set_key CA-6053 VEFF-3072  # Canadian Bank of Commerce National Historic Site
    set_key CA-6054 VEFF-3074  # Carlton House National Historic Site
    set_key CA-6055 VEFF-3075  # Claybank Brick Plant National Historic Site
    set_key CA-6056 VEFF-3076  # College Building National Historic Site
    set_key CA-6057 VEFF-3077  # Cumberland House National Historic Site
    set_key CA-6058 VEFF-3078  # Doukhobor Dugout House National Historic Site
    set_key CA-6059 VEFF-3079  # Doukhobors at Veregin National Historic Site
    set_key CA-6060 VEFF-3080  # Esterhazy Flour Mill National Historic Site
    set_key CA-6061 VEFF-3082  # Forestry Farm Park and Zoo National Historic Site
    set_key CA-6062 VEFF-3083  # Former Prince Albert City Hall National Historic Site
    set_key CA-6063 VEFF-3084  # Fort ? la Corne National Historic Site
    set_key CA-6064 VEFF-3085  # Fort Pitt National Historic Site
    set_key CA-6065 VEFF-3086  # Fort Qu'Appelle National Historic Site
    set_key CA-6066 VEFF-3087  # Government House National Historic Site
    set_key CA-6067 VEFF-3088  # Gravelbourg Ecclesiastical Buildings National Historic Site
    set_key CA-6068 VEFF-3089  # Humboldt Post Office National Historic Site
    set_key CA-6069 VEFF-3090  # Île-à-la-Crosse N.H.S.
    set_key CA-6070 VEFF-3091  # Keyhole Castle National Historic Site
    set_key CA-6071 VEFF-3093  # Seager Wheeler's Maple Grove Farm National Historic Site
    set_key CA-6072 VEFF-3094  # Steele Narrows National Historic Site
    set_key CA-6073 VEFF-3096  # Áísínai'pi N.H.S.
    set_key CA-6074 VEFF-3097  # Atlas No. 3 Coal Mine National Historic Site
    set_key CA-6075 VEFF-3098  # Banff Springs Hotel National Historic Site
    set_key CA-6076 VEFF-3099  # Beaulieu National Historic Site
    set_key CA-6077 VEFF-3100  # Blackfoot Crossing National Historic Site
    set_key CA-6078 VEFF-3101  # British Block Cairn National Historic Site
    set_key CA-6079 VEFF-3102  # Brooks Aqueduct National Historic Site
    set_key CA-6081 VEFF-3104  # Coleman National Historic Site
    set_key CA-6082 VEFF-3105  # Earthlodge Village National Historic Site
    set_key CA-6083 VEFF-3106  # Fort Assiniboine National Historic Site
    set_key CA-6084 VEFF-3107  # Fort Augustus and Fort Edmonton National Historic Site
    set_key CA-6085 VEFF-3108  # Fort Calgary National Historic Site
    set_key CA-6086 VEFF-3109  # Fort Chipewyan National Historic Site
    set_key CA-6087 VEFF-3110  # Fort Dunvegan National Historic Site
    set_key CA-6088 VEFF-4435  # Tiny Marsh Provincial Wildlife Area
    set_key CA-6089 VEFF-4404  # Marl Lake Resource Management Area
    set_key CA-6090 VEFF-4406  # Matchedash Bay Provincial Wildlife Area
    set_key CA-6091 VEFF-3567  # Lang Mill Conservation Area
    set_key CA-6095 VEFF-4082  # Fort William Historic Site
    set_key CA-6099 VEFF-4769  # Castalia Marsh
    set_key CA-6100 VEFF-3681  # Stewartville Swamp
    set_key CA-6103 VEFF-3801  # North Lake Provincial Park
    set_key CA-6104 VEFF-4755  # Annandale Rear Range Lighthouse
    set_key CA-6106 VEFF-4643  # Our Lady of Assumption Cathedral N.H.S.
    set_key CA-6114 VEFF-4327  # T'Railway Provincial Park
    set_key CA-6121 VEFF-3123  # Stephen Avenue National Historic Site
    set_key CA-6123 VEFF-3117  # Heritage Hall - Southern Alberta Institute of Technology National Heritage Site
    set_key CA-6124 VEFF-3115  # Fort Whoop Up National Historic Site
    set_key CA-6136 VEFF-3906  # Shelburne River Wilderness Area
    set_key CA-6157 VEFF-4716  # New Férolle Peninsula Lighthouse
    set_key CA-6158 VEFF-4705  # Cape Anguille Lighthouse
    set_key CA-6160 VEFF-4706  # Cape Ray Lighthouse
    set_key CA-6163 VEFF-4721  # Woody Point Lighthouse
    set_key CA-6164 VEFF-4717  # Rocky Point Lighthouse
    set_key CA-6166 VEFF-4707  # Cape St. Mary's Lighthouse
    set_key CA-6167 VEFF-4712  # Heart's Content Lighthouse
    set_key CA-6168 VEFF-4711  # Green Point Lighthouse
    set_key CA-6169 VEFF-4713  # Long Point (Twillingate) Lighthouse
    set_key CA-6172 VEFF-4759  # Seacow Head Lighthouse
    set_key CA-6176 VEFF-4336  # Boar's Head Lighthouse
    set_key CA-6178 VEFF-4337  # Cape George Lighthouse
    set_key CA-6179 VEFF-4339  # Cape St. Mary's Lighthouse
    set_key CA-6185 VEFF-4342  # Margaree Harbour Rear Range Lighthouse
    set_key CA-6192 VEFF-4344  # Prim Point Lighthouse
    set_key CA-6193 VEFF-4345  # Queensport Lighthouse
    set_key CA-6196 VEFF-4348  # Terence Bay Lighthouse
    set_key CA-6198 VEFF-4350  # Wallace Harbour Sector Lighthouse
    set_key CA-6205 VEFF-3384  # Île-Verte Lighthouse N.H.S.
    set_key CA-6206 VEFF-3385  # L'Isle-Verte Court House National Historic Site
    set_key CA-6208 VEFF-3432  # Ausable River Cut Conservation Area
    set_key CA-6209 VEFF-3537  # High Falls Conservation Area
    set_key CA-6210 VEFF-4065  # Battle of Chippawa National Historic Site
    set_key CA-6212 VEFF-3439  # Big Bend Conservation Area
    set_key CA-6213 VEFF-3465  # Clark Wright Conservation Area
    set_key CA-6214 VEFF-3469  # Coldstream Conservation Area
    set_key CA-6216 VEFF-4066  # Battle of Lundy's Lane National Historic Site
    set_key CA-6218 VEFF-4321  # Saint John Harbour Defense Network Historic Site
    set_key CA-6225 VEFF-4802  # Harpers Lake Nature Reserve
    set_key CA-6229 VEFF-4792  # Cap La Ronde Nature Reserve
    set_key CA-6232 VEFF-4797  # East River St. Marys Nature Reserve
    set_key CA-6234 VEFF-3793  # Fundy Trail Provincial Park
    set_key CA-6235 VEFF-4325  # Victoria County Court House Historic Site
    set_key CA-6236 VEFF-3807  # P'tit Sault Blockhouse Historic Site
    set_key CA-6237 VEFF-4314  # Église Saint-Pierre-aux-Liens Historic Site
    set_key CA-6238 VEFF-4309  # Capitol Theatre (Moncton) Historic Site
    set_key CA-6239 VEFF-4318  # Old Bathurst Post Office Historic Site
    set_key CA-6240 VEFF-4308  # CN Railways (Intercolonial Railway) Historic Site
    set_key CA-6241 VEFF-4319  # Old Carleton County Courthouse Historic Site
    set_key CA-6242 VEFF-4311  # Church of St. Andrew &amp; St. David Historic Site
    set_key CA-6243 VEFF-4316  # Kings County Courthouse Historic Site
    set_key CA-6244 VEFF-4324  # St. Paul's Anglican Church Historic Site
    set_key CA-6245 VEFF-4315  # Fort Tipperary Historic Site
    set_key CA-6246 VEFF-4323  # St. David's Presbyterian Church Historic Site
    set_key CA-6247 VEFF-4317  # Mineral Free Baptist Meetinghouse Historic Site
    set_key CA-6248 VEFF-4312  # Coverdale United Church Historic Site
    set_key CA-6258 VEFF-4723  # Congdon Creek Campground
    set_key CA-6259 VEFF-4726  # Dezadeash Lake Campground
    set_key CA-6260 VEFF-4754  # Yukon River Campground
    set_key CA-6261 VEFF-4753  # Tombstone Mountain Campground
    set_key CA-6262 VEFF-4752  # Tatchun Creek Campground
    set_key CA-6263 VEFF-4751  # Tarfu Lake Campground
    set_key CA-6264 VEFF-4750  # Takhini River Campground
    set_key CA-6265 VEFF-0849  # Tagish Bridge Territorial Park
    set_key CA-6266 VEFF-4749  # Squanga Lake Campground
    set_key CA-6267 VEFF-4748  # Snag Junction Campground
    set_key CA-6268 VEFF-4747  # Snafu Lake Campground
    set_key CA-6269 VEFF-4746  # Rock River Campground
    set_key CA-6270 VEFF-4745  # Quiet Lake South Campground
    set_key CA-6271 VEFF-4744  # Quiet Lake North Campground
    set_key CA-6272 VEFF-4743  # Pine Lake Campground
    set_key CA-6273 VEFF-4742  # Nunatuk Campground
    set_key CA-6274 VEFF-4741  # Nahanni Range Campground
    set_key CA-6275 VEFF-4740  # Moose Creek Campground
    set_key CA-6276 VEFF-4739  # Million Dollar Falls Campground
    set_key CA-6277 VEFF-4737  # Little Salmon Lake Campground
    set_key CA-6278 VEFF-4736  # Lapie Canyon Campground
    set_key CA-6279 VEFF-4735  # Lake Creek Campground
    set_key CA-6281 VEFF-4734  # Klondike River Campground
    set_key CA-6282 VEFF-4329  # Kathleen Lake Campground and Recreation Site
    set_key CA-6283 VEFF-4733  # Johnson Lake Campground
    set_key CA-6284 VEFF-4732  # Frenchman Lake Campground
    set_key CA-6285 VEFF-4731  # Frances Lake Campground
    set_key CA-6286 VEFF-4730  # Fox Lake Campground
    set_key CA-6287 VEFF-4729  # Ethel Lake Campground
    set_key CA-6288 VEFF-4728  # Engineer Creek Campground
    set_key CA-6289 VEFF-4727  # Drury Creek Campground
    set_key CA-6294 VEFF-3335  # Annapolis Royal Train Station
    set_key CA-6312 VEFF-4597  # Larry's Gulch Lodge Provincial Park
    set_key CA-6329 VEFF-4436  # Uxbridge Urban Provincial Park
    set_key CA-6338 VEFF-4202  # Dana Recreation Site
    set_key CA-6350 VEFF-4413  # Old Hay Bay Church N.H.S.
    set_key CA-6354 VEFF-3657  # Scanlon Creek Conservation Area
    set_key CA-6355 VEFF-3652  # Rogers Reservoir Conservation Area
    set_key CA-6356 VEFF-3588  # Mabel Davis Conservation Area
    set_key CA-6357 VEFF-3689  # Thornton Bales Conservation Area
    set_key CA-6359 VEFF-3604  # Mildmay-Carrick Conservation Area
    set_key CA-6362 VEFF-3460  # Cedar Beach
    set_key CA-6363 VEFF-3560  # Kopegaron Woods
    set_key CA-6364 VEFF-3692  # Tremblay Beach
    set_key CA-6365 VEFF-3655  # Ruscom Shores
    set_key CA-6367 VEFF-4937  # Kinghurst Conservation Area
    set_key CA-6370 VEFF-3551  # John R. Park Homestead
    set_key CA-6371 VEFF-0174  # Cedar Creek Conservation Area
    set_key CA-6388 VEFF-4764  # Dobson Trail
    set_key CA-6389 VEFF-4765  # Grande Digue Nature Preserve
    set_key CA-6390 VEFF-4766  # Wilson Family Nature Preserve
    set_key CA-6397 VEFF-3129  # Britannia Mines Concentrator N.H.S.
    set_key CA-6398 VEFF-3140  # Craigflower Manor House N.H.S
    set_key CA-6399 VEFF-3141  # Craigflower Schoolhouse N.H.S.
    set_key CA-6400 VEFF-4768  # Seal Cove Smoked Herring Stands N.H.S.
    set_key CA-6404 VEFF-4770  # Isle Haute
    set_key CA-6421 VEFF-4771  # Country Island National Wildlife Area
    set_key CA-6484 VEFF-4774  # Baie Verte Nature Reserve
    set_key CA-6485 VEFF-4775  # Cap Lumière Nature Reserve
    set_key CA-6486 VEFF-4776  # Grand Barachois Nature Reserve
    set_key CA-6498 VEFF-3779  # Beechwood Community Park
    set_key CA-6553 VEFF-4816  # Portobello Provincial Park
    set_key CA-6556 VEFF-4813  # Mount William Provincial Park
    set_key CA-6557 VEFF-4807  # Louis Head Provincial Park
    set_key CA-6558 VEFF-4804  # Horne Settlement Provincial Park
    set_key CA-6561 VEFF-4810  # Medway River Provincial Park
    set_key CA-6562 VEFF-4811  # Mersey River Provincial Park
    set_key CA-6563 VEFF-4782  # Baker Inlet Provincial Park
    set_key CA-6564 VEFF-4788  # Blanche Provincial Park
    set_key CA-6565 VEFF-4790  # Bulls Head Provincial Park
    set_key CA-6566 VEFF-0918  # Indian Fields Provincial Park Reserve
    set_key CA-6567 VEFF-4817  # Roseway Beach Provincial Park
    set_key CA-6568 VEFF-4815  # Pinehurst Provincial Park
    set_key CA-6569 VEFF-4806  # Linwood Provincial Park
    set_key CA-6570 VEFF-4809  # Mahoney Beach Provincial Park
    set_key CA-6571 VEFF-4812  # Monks Head Provincial Park
    set_key CA-6572 VEFF-4796  # Dunns Beach Provincial Park
    set_key CA-6600 VEFF-3869  # Mabou Provincial Park
    set_key CL-0001 CEFF-0018  # Lauca National Park
    set_key CL-0002 CEFF-0047  # Las Vicunas National Reserve
    set_key CL-0006 CEFF-0032  # Volcan Isluga National Park
    set_key CL-0007 CEFF-0048  # Pampa del Tamarugal National Reserve
    set_key CL-0008 CEFF-0094  # Morro Moreno National Park
    set_key CL-0009 CEFF-0020  # Llullaillaco National Park
    set_key CL-0010 CEFF-0050  # Los Flamencos
    set_key CL-0011 CEFF-0049  # La Chimba National Reserve
    set_key CL-0014 CEFF-0022  # Nevado de Tres Cruces National Park
    set_key CL-0015 CEFF-0019  # Llanos de Challe National Park
    set_key CL-0016 CEFF-0024  # Pan de Azucar National Park
    set_key CL-0017 CEFF-0005  # Bosque Fray Jorge National Park
    set_key CL-0018 CEFF-0051  # Ping�ino de Humboldt National Reserve
    set_key CL-0019 CEFF-0052  # Las Chinchillas
    set_key CL-0021 CEFF-0014  # La Campana
    set_key CL-0022 CEFF-0003  # Archipielago de Juan Fernandez
    set_key CL-0023 CEFF-0055  # El Yali
    set_key CL-0024 CEFF-0054  # Lago Pe�uelas
    set_key CL-0026 CEFF-0056  # Ro Clarillo
    set_key CL-0029 CEFF-0057  # Ro de Los Cipreses
    set_key CL-0030 CEFF-0061  # Radal Siete Tazas National Park
    set_key CL-0031 CEFF-0063  # Altos de Lircay
    set_key CL-0032 CEFF-0061  # Radal Siete Tazas National Reserve
    set_key CL-0033 CEFF-0065  # Bellotos El Melado
    set_key CL-0034 CEFF-0060  # Los Ruiles
    set_key CL-0035 CEFF-0062  # Federico Albert
    set_key CL-0036 CEFF-0059  # Laguna Torca
    set_key CL-0037 CEFF-0064  # Los Queules
    set_key CL-0038 CEFF-0068  # Huemules de Niblinto
    set_key CL-0039 CEFF-0066  # nuble
    set_key CL-0040 CEFF-0015  # Laguna del Laja
    set_key CL-0043 CEFF-0067  # Isla Mocha
    set_key CL-0044 CEFF-0069  # Ralco
    set_key CL-0045 CEFF-0021  # Nahuelbuta
    set_key CL-0046 CEFF-0028  # Tolhuaca
    set_key CL-0047 CEFF-0011  # Huerquehue
    set_key CL-0048 CEFF-0008  # Conguill
    set_key CL-0049 CEFF-0075  # China Muerta
    set_key CL-0050 CEFF-0072  # Nalcas
    set_key CL-0051 CEFF-0031  # Villarrica National Reserve
    set_key CL-0052 CEFF-0071  # Malalcahuello
    set_key CL-0053 CEFF-0070  # Alto Bo Bo
    set_key CL-0054 CEFF-0074  # Villarrica National Park
    set_key CL-0055 CEFF-0073  # Malleco
    set_key CL-0059 CEFF-0077  # Mocho-Choshuenco
    set_key CL-0060 CEFF-0025  # Puyehue
    set_key CL-0061 CEFF-0030  # Vicente Perez Rosales
    set_key CL-0063 CEFF-0009  # Corcovado
    set_key CL-0064 CEFF-0010  # Hornopir
    set_key CL-0065 CEFF-0002  # Alerce Andino
    set_key CL-0066 CEFF-0007  # Chiloe National Park
    set_key CL-0067 CEFF-0080  # Futaleuf
    set_key CL-0068 CEFF-0079  # Lago Palena
    set_key CL-0069 CEFF-0078  # Llanquihue
    set_key CL-0072 CEFF-0016  # Laguna San Rafael
    set_key CL-0073 CEFF-0013  # Isla Magdalena
    set_key CL-0074 CEFF-0026  # Queulat
    set_key CL-0075 CEFF-0083  # Cerro Castillo
    set_key CL-0076 CEFF-0012  # Isla Guamblin
    set_key CL-0079 CEFF-0084  # R.N. Ro Simpson
    set_key CL-0081 CEFF-0089  # Katalalixar
    set_key CL-0082 CEFF-0081  # Lago Rosselot
    set_key CL-0083 CEFF-0088  # Lago Las Torres
    set_key CL-0084 CEFF-0087  # Lago Carlota
    set_key CL-0085 CEFF-0085  # Coyhaique
    set_key CL-0086 CEFF-0082  # Las Guaitecas
    set_key CL-0089 CEFF-0023  # Pali-Aike
    set_key CL-0090 CEFF-0004  # Bernardo O'Higgins National Park
    set_key CL-0091 CEFF-0001  # Alberto de Agostini
    set_key CL-0092 CEFF-0029  # Torres del Paine
    set_key CL-0093 CEFF-0006  # Cabo de Hornos
    set_key CL-0095 CEFF-0093  # Laguna Parrillar
    set_key CL-0096 CEFF-0033  # Magallanes Province
    set_key CL-0103 CEFF-0017  # Las Palmas de Cocal
    set_key CL-0105 CEFF-0027  # Rapa Nui
    set_key CL-0106 CEFF-0053  # Rio Blanco
    set_key CL-0107 CEFF-0058  # Roblera Cobre Loncha
    set_key CL-0214 CEFF-0098  # Pen�nsula de Hualp�n
    set_key CL-0241 CEFF-0038  # Presidente Eduardo Frei Montalva Base (Air Force)
    set_key CO-0098 HKFF-0079  # Reserva La Nona
    set_key CO-0499 HKFF-0077  # Humedal Taboima
    set_key CO-0505 HKFF-0075  # Humedal Los Patos
    set_key CO-0510 HKFF-0078  # Laguna de Suesca
    set_key CR-0001 TIFF-0023  # Parque nacional Volcan Turrialba National Park
    set_key CR-0002 TIFF-0022  # Parque nacional Tortuguero National Park
    set_key CR-0003 TIFF-0021  # Parque nacional Volcan Tenorio Country Park
    set_key CR-0004 TIFF-0020  # Parque Nacional Tapanti National Park
    set_key CR-0005 TIFF-0019  # Parque nacional Santa Rosa National Park
    set_key CR-0006 TIFF-0018  # Parque nacional Rincon de la Vieja Country Park
    set_key CR-0007 TIFF-0017  # Parque nacional Volcan Poas Country Park
    set_key CR-0008 TIFF-0016  # Parque nacional Piedras Blancas National Park
    set_key CR-0009 TIFF-0015  # Parque nacional Palo Verde National Park
    set_key CR-0010 TIFF-0014  # Parque nacional Manuel Antonio National Park
    set_key CR-0011 TIFF-0013  # Parque nacional La Cangreja National Park
    set_key CR-0012 TIFF-0012  # Parque internacional La Amistad National Park
    set_key CR-0013 TIFF-0024  # Refugio Natural de Fauna Silvestre Bah�a Junquillal National Preserve
    set_key CR-0014 TIFF-0011  # Parque nacional Juan Castro Blanco National Park
    set_key CR-0015 TIFF-0010  # Parque Nacional Volcan Irazu?? Country Park
    set_key CR-0016 TIFF-0009  # Parque nacional Guanacaste National Park
    set_key CR-0017 TIFF-0008  # Parque Nacional Diria Country Park
    set_key CR-0018 TIFF-0007  # Parque nacional Corcovado National Park
    set_key CR-0019 TIFF-0005  # Parque nacional Chirripo Country Park
    set_key CR-0020 TIFF-0004  # Parque nacional Cahuita National Park
    set_key CR-0021 TIFF-0003  # Parque nacional Braulio Carrillo National Park
    set_key CR-0022 TIFF-0002  # Parque nacional Barra Honda National Park
    set_key CR-0023 TIFF-0001  # Parque nacional Volcan Arenal Country Park
    set_key CR-0024 TIFF-0006  # Cocos Island National Park
    set_key CU-0003 COFF-0003  # Lanzanillo - Pajonal - Fragoso Flora and Fauna Reserve
    set_key CU-0004 COFF-0002  # Limones-Tuabaquey Ecological Reserve
    set_key CU-0293 CMFF-0013  # Alejandro de Humboldt National Park
    set_key CU-0294 CMFF-0004  # Desembarco del Granma
    set_key CU-0304 CMFF-0010  # Topes de Collantes
    set_key CU-0317 CMFF-0007  # Pico Cristal
    set_key CU-0318 CMFF-0006  # Pico La Bayamesa
    set_key CU-0333 CMFF-0005  # Gran Piedra
    set_key CU-0546 CMFF-0013  # Alejandro de Humboldt National Park
    set_key CW-0001 PAFF-0021  # Sint Christoffel Provincial Park (PJ2)
    set_key CW-0002 PAFF-0022  # Shete Boka Provincial Park (PJ2)
    set_key DM-0001 J7FF-0001  # Cabrits National Park
    set_key DM-0003 J7FF-0003  # Morne Trois Pitons
    set_key DM-0004 J7FF-0002  # Morne Diablotin National Park
    set_key DO-0015 HIFF-0001  # Armando Berm?dez National Park
    set_key DO-0018 HIFF-0003  # Cotubanamá (Del Este) National Park
    set_key DO-0022 HIFF-0007  # Jaragua National Park
    set_key DO-0023 HIFF-0008  # Jose del Carmen Ramirez National Park
    set_key DO-0026 HIFF-0011  # Lago Enriquillo e Isla Cabritos National Park
    set_key DO-0027 HIFF-0012  # Los Haitises National Park
    set_key DO-0058 HIFF-0005  # Loma Isabel de Torres National Monument
    set_key DO-0111 HIFF-0013  # Monte Cristi National Park
    set_key EC-0001 HCFF-0001  # Cajas National Park
    set_key EC-0002 HCFF-0002  # Cotopaxi National Park
    set_key EC-0004 HCFF-0004  # Galapagos National Park
    set_key EC-0006 HCFF-0006  # Machalilla National Park
    set_key EC-0007 HCFF-0007  # Podocarpus National Park
    set_key EC-0009 HCFF-0011  # Chimborazo National Wildlife Refuge
    set_key EC-0014 HCFF-0009  # Parque Lago National Recreation Area
    set_key EC-0023 HCFF-0005  # Llanganates National Park
    set_key EC-0027 HCFF-0012  # Manglares Churute Ecological Reserve
    set_key GL-0001 OZFF-0005  # Northeast Greenland Nature Reserve
    set_key GP-0003 FFF-1000  # La Desirade
    set_key GP-0019 FFF-1007  # Folle Anse Conservatoire du Littoral
    set_key GP-0024 FFF-0990  # Le Chameau
    set_key GU-0001 KFF-0110  # Guam National Wildlife Refuge
    set_key GY-0001 8RFF-0001  # Kaieteur National Park
    set_key GY-0002 8RFF-0002  # Kanashen Amerindian Protected Area
    set_key GY-0003 8RFF-0003  # Iwokrama Rainforest
    set_key GY-0004 8RFF-0004  # Shell Beach Protected Area
    set_key GY-0005 8RFF-0005  # Kanuku Mountains Protected Area
    set_key GY-0006 8RFF-0006  # Joe Vieira Park
    set_key GY-0008 8RFF-0008  # National Park
    set_key GY-0009 8RFF-0007  # Guyana Zoological Park and Wildlife Rescue Center
    set_key IS-0002 TFFF-0004  # �ingvellir
    set_key IS-0003 TFFF-0007  # Fri�land a� Fjallabaki
    set_key IS-0004 TFFF-0002  # Skaftafell - Vatnaj�kuls�j��gar�ur
    set_key IS-0005 TFFF-0008  # L�ns�r�fi - Vatnaj�kuls�j��gar�ur
    set_key IS-0006 TFFF-0005  # H�lmanes
    set_key IS-0007 TFFF-0001  # J�kuls�rglj�fur - Vatnaj�kuls�j��gar�ur
    set_key IS-0008 TFFF-0006  # Vestmannsvatn Nature Reserve
    set_key IS-0009 TFFF-0012  # Svarfa�ardardalur Nature Reserve
    set_key IS-0010 TFFF-0009  # M�vatn
    set_key IS-0011 TFFF-0011  # Gu�laugstungur
    set_key IS-0012 TFFF-0003  # Sn�fellsj�kull
    set_key IS-0013 TFFF-0013  # Dyrh�laey Nature Reserve
    set_key IS-0014 TFFF-0014  # H�safellssk�gur
    set_key IS-0015 TFFF-0015  # Geitland
    set_key IS-0016 TFFF-0016  # Herd�sarv�k
    set_key IS-0026 TFFF-0020  # B�r�alaug
    set_key IS-0027 TFFF-0021  # Str�ndin vi� Stapa og Hellna
    set_key IS-0028 TFFF-0022  # B��ahraun
    set_key IS-0029 TFFF-0023  # Eldborg i Hnappadal
    set_key IS-0033 TFFF-0019  # Hraunfossar og Barnafoss
    set_key IS-0080 TFFF-0017  # Geysir � Haukadal
    set_key IS-0081 TFFF-0018  # Gullfoss
    set_key JM-0001 6YFF-0003  # Blue and John Crow Mountains National Park
    set_key JM-0003 6YFF-0001  # Fort Montego State Historic Site
    set_key MQ-0001 FFF-0039  # Parc Regional de la Martinique
    set_key MQ-0024 FFF-0366  # Reserve Naturelle de la Presqu'lle de la Caravelle
    set_key MQ-0026 FFF-0428  # Etang des Salines
    set_key MQ-0027 FFF-0416  # Versants Nord Ouest de la Montagne Pel
    set_key MX-0002 XEFF-0064  # Sierra de San Pedro Martir National Park
    set_key MX-0003 XEFF-0010  # Cabo Pulmo National Park
    set_key MX-0005 XEFF-0050  # Lagunas de Montebello National Park
    set_key MX-0006 XEFF-0021  # Cumbres de Majalca National Park
    set_key MX-0007 NIL-0000  # Desierto de los Leones National Park; WWFF candidates: XEFF-0024, XEFF-0025
    set_key MX-0008 XEFF-0054  # Los Novillos National Park
    set_key MX-0009 XEFF-0072  # Revillagigedo National Park
    set_key MX-0012 XEFF-0038  # Grutas de Cacahuamilpa National Park
    set_key MX-0013 XEFF-0053  # Los Marmoles National Park
    set_key MX-0014 XEFF-0069  # Nevado de Colima National Park
    set_key MX-0016 XEFF-0015  # Cerro de Garnica National Park
    set_key MX-0018 XEFF-0043  # Isla Isabel National Park
    set_key MX-0019 XEFF-0032  # El Sabinal National Park
    set_key MX-0020 XEFF-0049  # Lagunas de Chacahua National Park
    set_key MX-0021 XEFF-0045  # Iztaccihuatl-Popocatepetl National Park
    set_key MX-0022 XEFF-0017  # Cerro de las Campanas National Park
    set_key MX-0023 XEFF-0068  # Tulum National Park
    set_key MX-0024 XEFF-0031  # El Potosi National Park
    set_key MX-0029 XEFF-0046  # La Malinche National Park
    set_key MX-0030 XEFF-0061  # Pico de Orizaba National Park
    set_key MX-0031 XEFF-0027  # Dzibilchantun National Park
    set_key MX-0032 XEFF-0065  # Sierra de Organos National Park
    set_key MX-0033 XEFF-0022  # Cumbres de Monterrey National Park
    set_key MX-0035 XEFF-0002  # Arrecife Alacranes
    set_key MX-0036 XEFF-0019  # Constitucion de 1857 National Park
    set_key MX-0038 XEFF-0006  # Bahia de Loreto National Park
    set_key MX-0040 XEFF-0012  # Canon del Sumidero
    set_key MX-0041 XEFF-0059  # Palenque National Park
    set_key MX-0042 XEFF-0013  # Cascada de Basaseachi National Park
    set_key MX-0043 XEFF-0041  # Insurgente Miguel Hiidalgo y Costilla National Park
    set_key MX-0044 XEFF-0023  # Cumbres del Ajusco National Park
    set_key MX-0045 XEFF-0036  # Fuentes Brotantes de Tlalpan National Park
    set_key MX-0046 XEFF-0033  # El Tepeyac National Park
    set_key MX-0047 XEFF-0052  # Lomas de Padierna National Park
    set_key MX-0048 XEFF-0016  # Cerro del al Estrella National Park
    set_key MX-0049 XEFF-0030  # El Historico Coyoac
    set_key MX-0050 XEFF-0037  # General Juan N. Alvarez National Park
    set_key MX-0051 XEFF-0035  # El Veladero National Park
    set_key MX-0052 XEFF-0067  # Tula National Park
    set_key MX-0053 XEFF-0056  # Mineral del Chico
    set_key MX-0054 XEFF-0057  # Molino de Flores Nezahualcoyotl National Park
    set_key MX-0055 XEFF-0055  # Los Remedios National Park
    set_key MX-0056 XEFF-0063  # Sacromonte National Park
    set_key MX-0057 XEFF-0026  # Desierto del Carmen National Park
    set_key MX-0058 XEFF-0062  # Rayon National Park
    set_key MX-0059 XEFF-0007  # Barranca de Cupatitzio National Park
    set_key MX-0060 XEFF-0040  # Insurgente Jose Maria Morelos y Pav?n
    set_key MX-0061 XEFF-0009  # Bosencheve National Park
    set_key MX-0062 XEFF-0051  # Lagunas de Zempoala National Park
    set_key MX-0063 XEFF-0034  # El Tepozteco National Park
    set_key MX-0064 XEFF-0044  # Islas Marietas National Park
    set_key MX-0065 XEFF-0008  # Benito Juarez National Park
    set_key MX-0066 XEFF-0039  # Huatulco National Park
    set_key MX-0067 XEFF-0028  # El Cimatario National Park
    set_key MX-0068 XEFF-0020  # Costa Occidental de Isla Mujeres National Park
    set_key MX-0069 XEFF-0004  # Arrecifes de Cozumel National Park
    set_key MX-0070 XEFF-0003  # Arrecife de Puerto Morelos National Park
    set_key MX-0071 XEFF-0042  # Isla Contoy National Park
    set_key MX-0073 XEFF-0029  # El Gogorron
    set_key MX-0075 XEFF-0018  # Cofre de Perote National Park
    set_key MX-0076 XEFF-0011  # Canon del Rio Blanco
    set_key MX-0077 XEFF-0066  # Sistema Arrecifal Veracruzano National Park
    set_key MX-0127 XEFF-0074  # Monarch Butterfly
    set_key MX-0128 XEFF-0058  # Nevado de Toluca Flora and Fauna Reserve
    set_key MX-0141 XEFF-0073  # Arrecifes de Sian Ka'an Biosphere Reserve
    set_key MX-0142 XEFF-0005  # Arrecifes de Xcalak National Park
    set_key MX-0144 XEFF-0076  # Balandra - Zona N�cleo
    set_key MX-0150 XEFF-0009  # Bosencheve National Park
    set_key MX-0151 XEFF-0075  # El Vizcaino Biosphere Reserve
    set_key MX-0177 XEFF-0048  # Lago de Cam?cuaro National Park
    set_key MX-0185 XEFF-0078  # Biosphere Reserve of Mapimi
    set_key MX-0189 XEFF-0001  # San Lorenzo National Park
    set_key MX-0199 XEFF-0060  # Pico de Tanc?taro Flora and Fauna Reserve
    set_key MX-0230 XEFF-0077  # Sierra La Laguna Biosphere Reserve
    set_key MX-0361 XEFF-0070  # Xochit?catl Archeological Reserve
    set_key NI-0001 YNFF-0003  # Volc�n Masaya
    set_key NI-0003 YNFF-0001  # Archipi�lago de Zapatera
    set_key NI-0004 YNFF-0002  # Cerro Saslaya
    set_key NI-0055 YNFF-0004  # Complejo Volc�nico San Crist�bal � Casitas-Chonco
    set_key PA-0008 HPFF-0010  # La Amistad National Park
    set_key PA-0009 HPFF-0009  # Isla Coiba
    set_key PA-0010 HPFF-0005  # Darien National Park
    set_key PA-0011 HPFF-0004  # Chagres National Park
    set_key PA-0012 HPFF-0011  # Portobelo National Park
    set_key PA-0013 HPFF-0013  # Soberania National Park
    set_key PA-0014 HPFF-0002  # Camino de Cruces National Park
    set_key PA-0015 HPFF-0006  # Omar Torrijos National Park
    set_key PA-0017 HPFF-0001  # Altos de Campana National Park
    set_key PA-0018 HPFF-0012  # Sarigua National Park
    set_key PA-0019 HPFF-0003  # Cerro Hoya National Park
    set_key PA-0020 HPFF-0014  # Volcan Baru National Park
    set_key PA-0021 HPFF-0008  # Isla Bastimentos National Marine Park
    set_key PA-0022 HPFF-0007  # Golfo de Chiriqui National Marine Park
    set_key PA-0027 HPFF-0015  # Isla Iguana Wilderness Protection Area
    set_key PM-0001 FFF-0415  # Isthme de Miquelon-Langlade
    set_key PM-0002 FFF-3648  # Anse A Henry
    set_key PR-0001 KFF-0103  # El Yunque National Forest
    set_key PR-0002 KFF-0104  # Bosque Estatal Toro Negro State Forest
    set_key PR-0003 KFF-0106  # Rio Camuy Cave State Park
    set_key PR-0004 KFF-0108  # Isla De Mona E Islote Monito Natural Reserve
    set_key PR-0005 KFF-0132  # Cabo Rojo National Wildlife Refuge
    set_key PR-0006 KFF-0134  # Laguna Cartagena National Wildlife Refuge
    set_key PR-0007 KFF-0135  # Vieques National Wildlife Refuge
    set_key PR-0008 KFF-0317  # Shell Keys National Wildlife Refuge
    set_key PR-0009 KFF-0323  # Massasoit National Wildlife Refuge
    set_key PR-0010 KFF-0351  # Michigan Islands National Wildlife Refuge
    set_key PR-0011 KFF-0363  # Mille Lacs National Wildlife Refuge
    set_key PR-0021 KFF-0107  # Guajataca State Forest
    set_key PR-0022 KFF-0109  # Guanica Forest Biosphere Reserve
    set_key PR-0027 KFF-0105  # Pinones Park
    set_key PR-0058 KFF-4571  # Culebra National Wildlife Refuge Wildlife Refuge
    set_key PR-0082 KFF-6907  # Tres Palmas Marine Reserve
    set_key PR-0090 KFF-0133  # Desecheo National Wildlife Refuge
    set_key TC-0001 VPFF-5005  # Princess Alexandra National Park (VP5)
    set_key TC-0002 VPFF-5004  # Northwest Point National Park (VP5)
    set_key TC-0003 VPFF-5001  # Chalk Sound National Park (VP5)
    set_key TC-0005 VPFF-5002  # East Bay Islands National Park (VP5)
    set_key UM-0001 KFF-0111  # Baker Island National Wildlife Refuge
    set_key UM-0002 KFF-0112  # Johnston Island National Wildlife Refuge
    set_key UM-0003 KFF-0113  # Kingman Reef National Wildlife Refuge
    set_key UM-0004 KFF-0114  # Midway Atoll National Wildlife Refuge
    set_key UM-0005 KFF-0115  # Jarvis Island National Wildlife Refuge
    set_key UM-0006 KFF-0116  # Palmyra Atoll National Wildlife Refuge
    set_key UM-0007 KFF-0122  # Howland Island National Wildlife Refuge
    set_key UM-0008 KFF-0131  # Navassa Island National Wildlife Refuge
    set_key UM-0009 KFF-4572  # Wake Island National Wildlife Refuge
    set_key US-0001 KFF-0001  # Acadia National Park
    set_key US-0002 KFF-0002  # Alagnak Wild River National Park
    set_key US-0003 KFF-0003  # Aniakchak National Preserve
    set_key US-0004 KFF-0004  # Arches National Park
    set_key US-0005 KFF-0005  # Badlands National Park
    set_key US-0006 KFF-0006  # Big Bend National Park
    set_key US-0007 KFF-0007  # Biscayne Bay National Park
    set_key US-0008 KFF-0008  # Black Canyon of the Gunnison National Park
    set_key US-0009 KFF-0009  # Bryce Canyon National Park
    set_key US-0010 KFF-0010  # Canyonlands National Park
    set_key US-0011 KFF-0011  # Capitol Reef National Park
    set_key US-0012 KFF-0012  # Carlsbad Caverns National Park
    set_key US-0013 KFF-0013  # Chaco Culture National Historical Park
    set_key US-0014 KFF-0014  # Channel Islands National Park
    set_key US-0015 NIL-0000  # Chesapeake and Ohio Canal (DofC); WWFF candidates: KFF-0015, KFF-4599
    set_key US-0016 KFF-0016  # Colonial National Historical Park
    set_key US-0017 KFF-0017  # Congaree National Park
    set_key US-0018 KFF-0018  # Crater Lake National Park
    set_key US-0019 NIL-0000  # Cumberland Gap National Historical Park (VA); WWFF candidates: KFF-0019, KFF-4586, KFF-4587
    set_key US-0020 KFF-0020  # Cuyahoga Valley National Park
    set_key US-0021 NIL-0000  # Death Valley National Park (NV); WWFF candidates: KFF-0021, KFF-4602
    set_key US-0022 KFF-0022  # Denali National Park
    set_key US-0023 KFF-0023  # Dry Tortugas National Park
    set_key US-0024 KFF-0024  # Everglades National Park
    set_key US-0026 KFF-0026  # Gates of the Arctic National Park
    set_key US-0027 KFF-0027  # Gettysburg National Military Park
    set_key US-0028 KFF-0028  # Glacier National Park
    set_key US-0029 KFF-0029  # Glacier Bay National Preserve
    set_key US-0030 KFF-0030  # Grand Canyon National Park
    set_key US-0031 KFF-0031  # Grand Teton National Park
    set_key US-0032 KFF-0032  # Great Basin National Park
    set_key US-0033 KFF-0033  # Great Sand Dunes National Park
    set_key US-0034 NIL-0000  # Great Smoky Mountains National Park (NC); WWFF candidates: KFF-0034, KFF-4709
    set_key US-0035 KFF-0035  # Guadalupe Mountains National Park
    set_key US-0036 KFF-0036  # Haleakala National Park
    set_key US-0037 KFF-0037  # Hawai'i Volcanoes National Park
    set_key US-0038 KFF-0038  # Hot Springs National Park
    set_key US-0039 KFF-0039  # Isle Royale National Park
    set_key US-0040 KFF-0040  # Jean Lafitte National Historical Park
    set_key US-0041 KFF-0041  # Joshua Tree National Park
    set_key US-0043 KFF-0043  # Kalaupapa National Historical Park
    set_key US-0044 KFF-0044  # Katmai National Park
    set_key US-0045 KFF-0045  # Kenai Fjords National Park
    set_key US-0046 KFF-0046  # Kings Canyon National Park
    set_key US-0047 KFF-0047  # Kobuk Valley National Park
    set_key US-0048 KFF-0048  # Lake Clark National Park
    set_key US-0049 KFF-0049  # Lassen Volcanic National Park
    set_key US-0050 KFF-0050  # Mammoth Cave National Park
    set_key US-0051 KFF-0051  # Mesa Verde National Park
    set_key US-0052 KFF-0052  # Mount Rainier National Park
    set_key US-0054 KFF-0054  # Nez Perce National Historical Park (MT)
    set_key US-0055 KFF-0055  # North Cascades National Park
    set_key US-0056 KFF-0056  # Olympic National Park
    set_key US-0057 KFF-0057  # Petrified Forest National Park
    set_key US-0058 KFF-0058  # Redwood National Park
    set_key US-0059 KFF-0059  # Rocky Mountain National Park
    set_key US-0060 KFF-0060  # Saguaro National Park
    set_key US-0061 KFF-0061  # San Juan Island National Historical Park
    set_key US-0062 KFF-0062  # Saratoga National Historical Park
    set_key US-0063 KFF-0063  # Sequoia National Park
    set_key US-0064 KFF-0064  # Shenandoah National Park
    set_key US-0065 KFF-0065  # Theodore Roosevelt National Park
    set_key US-0067 KFF-0067  # Voyageurs National Park
    set_key US-0068 KFF-0068  # Wind Cave National Park
    set_key US-0069 KFF-0069  # Wrangell-St. Elias National Park
    set_key US-0070 NIL-0000  # Yellowstone National Park (ID); WWFF candidates: KFF-0070, KFF-4710, KFF-4711
    set_key US-0071 KFF-0071  # Yosemite National Park
    set_key US-0072 KFF-0072  # Zion National Park
    set_key US-0117 KFF-0117  # Hakalau Forest National Wildlife Refuge
    set_key US-0118 KFF-0118  # Hanalei National Wildlife Refuge
    set_key US-0119 KFF-0119  # Hawaiian Islands National Wildlife Refuge
    set_key US-0120 KFF-6097  # Ginkgo Petrified Forest State Park
    set_key US-0121 KFF-0121  # Kure Atoll State Wildlife Area
    set_key US-0123 KFF-0123  # Huleia National Wildlife Refuge
    set_key US-0124 KFF-0124  # James Campbell National Wildlife Refuge
    set_key US-0125 KFF-0125  # Kakahaia National Wildlife Refuge
    set_key US-0126 KFF-0126  # Kealia Pond National Wildlife Refuge
    set_key US-0127 KFF-0127  # Kilauea Point National Wildlife Refuge
    set_key US-0128 KFF-0128  # O'ahu Forest National Wildlife Refuge
    set_key US-0129 KFF-0129  # Pearl Harbor National Wildlife Refuge
    set_key US-0136 KFF-0136  # Bon Secour National Wildlife Refuge
    set_key US-0137 KFF-0137  # Cahaba River National Wildlife Refuge
    set_key US-0138 KFF-0138  # Choctaw National Wildlife Refuge
    set_key US-0139 KFF-0139  # Eufaula National Wildlife Refuge
    set_key US-0140 KFF-0140  # Fern Cave National Wildlife Refuge
    set_key US-0141 KFF-0141  # Key Cave National Wildlife Refuge
    set_key US-0142 KFF-0142  # Arctic National Wildlife Refuge
    set_key US-0143 KFF-0143  # Alaska Maritime National Wildlife Refuge
    set_key US-0144 KFF-0144  # Alaska Peninsula National Wildlife Refuge
    set_key US-0145 KFF-0145  # Becharof National Wildlife Refuge
    set_key US-0146 KFF-0146  # Innoko National Wildlife Refuge
    set_key US-0147 KFF-0147  # Izembek National Wildlife Refuge
    set_key US-0148 KFF-0148  # Kanuti National Wildlife Refuge
    set_key US-0149 KFF-0149  # Kenai National Wildlife Refuge
    set_key US-0150 KFF-0150  # Kodiak National Wildlife Refuge
    set_key US-0151 KFF-0151  # Koyukuk National Wildlife Refuge
    set_key US-0152 KFF-0152  # Nowitna National Wildlife Refuge
    set_key US-0153 KFF-0153  # Selawik National Wildlife Refuge
    set_key US-0154 KFF-0154  # Tetlin National Wildlife Refuge
    set_key US-0155 KFF-0155  # Togiak National Wildlife Refuge
    set_key US-0156 KFF-0156  # Yukon Delta National Wildlife Refuge
    set_key US-0157 KFF-0157  # Yukon Flats National Wildlife Refuge
    set_key US-0158 KFF-0158  # Mountain Longleaf National Wildlife Refuge
    set_key US-0159 KFF-0159  # Sauta Cave National Wildlife Refuge
    set_key US-0160 KFF-0160  # Watercress Darter National Wildlife Refuge
    set_key US-0161 KFF-0161  # Wheeler National Wildlife Refuge
    set_key US-0162 KFF-0162  # Bald Knob National Wildlife Refuge
    set_key US-0163 KFF-0163  # Big Lake National Wildlife Refuge
    set_key US-0164 KFF-0164  # Cache River National Wildlife Refuge
    set_key US-0165 KFF-0165  # Felsenthal National Wildlife Refuge
    set_key US-0166 KFF-0166  # Holla Bend National Wildlife Refuge
    set_key US-0167 KFF-0167  # Logan Cave National Wildlife Refuge
    set_key US-0168 KFF-0168  # Overflow National Wildlife Refuge
    set_key US-0169 KFF-0169  # Pond Creek National Wildlife Refuge
    set_key US-0170 KFF-0170  # Wapanocca National Wildlife Refuge
    set_key US-0171 KFF-0171  # White River National Wildlife Refuge
    set_key US-0172 KFF-0172  # Bill Williams River National Wildlife Refuge
    set_key US-0173 KFF-0173  # Buenos Aires National Wildlife Refuge
    set_key US-0174 KFF-0174  # Cabeza Prieta National Wildlife Refuge
    set_key US-0175 NIL-0000  # Cibola National Wildlife Refuge (AZ); WWFF candidates: KFF-0175, KFF-7365
    set_key US-0176 KFF-0176  # Imperial National Wildlife Refuge
    set_key US-0177 KFF-0177  # Kofa National Wildlife Refuge
    set_key US-0178 KFF-0178  # Leslie Canyon National Wildlife Refuge
    set_key US-0179 KFF-0179  # San Bernardino National Wildlife Refuge
    set_key US-0180 KFF-0180  # Antioch Dunes National Wildlife Refuge
    set_key US-0181 KFF-0181  # Bitter Creek National Wildlife Refuge
    set_key US-0182 KFF-0182  # Blue Ridge National Wildlife Refuge
    set_key US-0183 NIL-0000  # Penrose Commons National Recreation Area
    set_key US-0184 NIL-0000  # Ramah State Wildlife Area
    set_key US-0185 NIL-0000  # Hugo State Wildlife Area
    set_key US-0186 KFF-0186  # Coachella Valley National Wildlife Refuge
    set_key US-0187 KFF-0187  # Colusa National Wildlife Refuge
    set_key US-0188 KFF-0188  # Kinney Lake State Wildlife Area
    set_key US-0189 KFF-0189  # Don Edwards San Francisco Bay National Wildlife Refuge
    set_key US-0190 KFF-7261  # Flagler Reservoir State Wildlife Area
    set_key US-0191 NIL-0000  # Brush Hollow State Wildlife Area
    set_key US-0192 KFF-0192  # Grasslands Wildlife Management Area
    set_key US-0193 KFF-0193  # Guadalupe-Nipomo Dunes National Wildlife Refuge
    set_key US-0194 KFF-0194  # Havasu National Wildlife Refuge
    set_key US-0195 KFF-0195  # Hopper Mountain National Wildlife Refuge
    set_key US-0196 KFF-0196  # Humboldt Bay National Wildlife Refuge
    set_key US-0197 KFF-0197  # Kern National Wild and Scenic River
    set_key US-0198 KFF-0198  # Kesterson National Wildlife Refuge
    set_key US-0199 NIL-0000  # Lower Klamath National Wildlife Refuge (OR); WWFF candidates: KFF-0199, KFF-6747
    set_key US-0200 KFF-0200  # Marin Islands National Wildlife Refuge
    set_key US-0201 KFF-0201  # Merced National Wild and Scenic River
    set_key US-0202 KFF-0202  # Modoc National Wildlife Refuge
    set_key US-0203 KFF-0203  # North Central Valley Wildlife Management Area
    set_key US-0204 KFF-0204  # Pixley National Wildlife Refuge
    set_key US-0205 KFF-0205  # Sacramento National Wildlife Refuge
    set_key US-0206 KFF-0206  # Sacramento River National Wildlife Refuge
    set_key US-0207 KFF-0207  # Salinas River National Wildlife Refuge
    set_key US-0208 KFF-0208  # San Diego National Wildlife Refuge
    set_key US-0209 KFF-0209  # San Diego Bay National Wildlife Refuge
    set_key US-0210 KFF-0210  # San Joaquin River National Wildlife Refuge
    set_key US-0211 KFF-0211  # San Luis National Wildlife Refuge
    set_key US-0212 KFF-0212  # San Pablo Bay National Wildlife Refuge
    set_key US-0213 KFF-0213  # Seal Beach National Wildlife Refuge
    set_key US-0214 KFF-0214  # Sonny Bono Salton Sea National Wildlife Refuge
    set_key US-0215 KFF-0215  # Stone Lakes National Wildlife Refuge
    set_key US-0216 KFF-0216  # Sutter National Wildlife Refuge
    set_key US-0217 KFF-0217  # Tijuana Slough National Wildlife Refuge
    set_key US-0218 KFF-0218  # Tule Lake National Wildlife Refuge
    set_key US-0219 KFF-0219  # Willow Creek-Lurline Wildlife Management Area
    set_key US-0220 KFF-0220  # Alamosa National Wildlife Refuge
    set_key US-0221 KFF-0221  # Arapaho National Wildlife Refuge
    set_key US-0222 KFF-0222  # Baca National Wildlife Refuge
    set_key US-0223 KFF-0223  # Browns Park National Wildlife Refuge
    set_key US-0224 KFF-0224  # Monte Vista National Wildlife Refuge
    set_key US-0225 KFF-0225  # Rocky Flats National Wildlife Refuge
    set_key US-0226 KFF-0226  # Rocky Mountain Arsenal National Wildlife Refuge
    set_key US-0227 KFF-0227  # Two Ponds National Wildlife Refuge
    set_key US-0228 KFF-0228  # Stewart B. Mckinney National Wildlife Refuge
    set_key US-0229 KFF-0229  # Bombay Hook National Wildlife Refuge
    set_key US-0230 KFF-0230  # Prime Hook National Wildlife Refuge
    set_key US-0231 KFF-0231  # Archie Carr National Wildlife Refuge
    set_key US-0232 KFF-0232  # Arthur R. Marshall Loxahatchee National Wildlife Refuge
    set_key US-0233 KFF-0233  # Caloosahatchee National Wildlife Refuge
    set_key US-0234 KFF-0234  # Cedar Keys National Wildlife Refuge
    set_key US-0235 KFF-0235  # Chassahowitzka National Wildlife Refuge
    set_key US-0236 KFF-0236  # Crocodile Lake National Wildlife Refuge
    set_key US-0237 KFF-0237  # Crystal River National Wildlife Refuge
    set_key US-0238 KFF-0238  # Egmont Key National Wildlife Refuge
    set_key US-0239 KFF-0239  # Florida Panther National Wildlife Refuge
    set_key US-0240 KFF-0240  # Great White Heron National Wildlife Refuge
    set_key US-0241 KFF-0241  # Hobe Sound National Wildlife Refuge
    set_key US-0243 KFF-0243  # J.N. Ding Darling National Wildlife Refuge
    set_key US-0244 KFF-0244  # Key West National Wildlife Refuge
    set_key US-0246 KFF-0246  # Lake Woodruff National Wildlife Refuge
    set_key US-0247 KFF-0247  # Lower Suwannee National Wildlife Refuge
    set_key US-0248 KFF-0248  # Matlacha Pass National Wildlife Refuge
    set_key US-0249 KFF-0249  # Merritt Island National Wildlife Refuge
    set_key US-0250 KFF-0250  # National Key Deer National Wildlife Refuge
    set_key US-0252 KFF-0252  # Pelican Island National Wildlife Refuge
    set_key US-0255 KFF-0255  # St. Johns National Wildlife Refuge
    set_key US-0256 KFF-0256  # St. Marks National Wildlife Refuge
    set_key US-0257 KFF-0257  # St. Vincent National Wildlife Refuge
    set_key US-0258 KFF-0258  # Ten Thousand Islands National Wildlife Refuge
    set_key US-0259 KFF-0259  # Banks Lake National Wildlife Refuge
    set_key US-0260 KFF-0260  # Blackbeard Island National Wildlife Refuge
    set_key US-0261 KFF-0261  # Bond Swamp National Wildlife Refuge
    set_key US-0262 KFF-0262  # Harris Neck National Wildlife Refuge
    set_key US-0263 KFF-0263  # Okefenokee National Wildlife Refuge
    set_key US-0264 KFF-0264  # Piedmont National Wildlife Refuge
    set_key US-0265 KFF-0265  # Pinckney Island National Wildlife Refuge
    set_key US-0266 KFF-0266  # Wassaw National Wildlife Refuge
    set_key US-0267 KFF-0267  # Wolf Island National Wildlife Refuge
    set_key US-0268 KFF-0268  # DeSoto National Wildlife Refuge (IA)
    set_key US-0269 KFF-0269  # Driftless Area National Wildlife Refuge
    set_key US-0270 KFF-0270  # Iowa Wetland Management District
    set_key US-0271 KFF-0271  # Neal Smith National Wildlife Refuge
    set_key US-0272 NIL-0000  # Port Louisa National Wildlife Refuge (IA); WWFF candidates: KFF-0272, KFF-4622
    set_key US-0273 KFF-0273  # Union Slough National Wildlife Refuge
    set_key US-0274 KFF-0274  # Bear Lake National Wildlife Refuge
    set_key US-0275 KFF-0275  # Camas National Wildlife Refuge
    set_key US-0276 KFF-0276  # Deer Flat National Wildlife Refuge
    set_key US-0277 KFF-0277  # Grays Lake National Wildlife Refuge
    set_key US-0278 KFF-0278  # Kootenai National Wildlife Refuge
    set_key US-0279 KFF-0279  # Minidoka National Wildlife Refuge
    set_key US-0280 KFF-0280  # Oxford Slough Wetland Management District
    set_key US-0281 KFF-0281  # Chautauqua National Wildlife Refuge
    set_key US-0282 KFF-0282  # Crab Orchard National Wildlife Refuge
    set_key US-0283 KFF-0283  # Cypress Creek National Wildlife Refuge
    set_key US-0284 KFF-0284  # Emiquon National Wildlife Refuge
    set_key US-0285 KFF-0285  # Meredosia National Wildlife Refuge
    set_key US-0286 KFF-0286  # Middle Mississippi River National Wildlife Refuge
    set_key US-0287 NIL-0000  # Two Rivers National Wildlife Refuge (MO); WWFF candidates: KFF-0287, KFF-4623
    set_key US-0288 KFF-0288  # Big Oaks National Wildlife Refuge
    set_key US-0289 KFF-0289  # Muscatatuck National Wildlife Refuge
    set_key US-0290 KFF-0290  # Patoka River National Wildlife Refuge
    set_key US-0291 KFF-0291  # Flint Hills National Wildlife Refuge
    set_key US-0292 KFF-0292  # Kirwin National Wildlife Refuge
    set_key US-0293 KFF-0293  # Marais Des Cygnes National Wildlife Refuge
    set_key US-0294 KFF-0294  # Quivira National Wildlife Refuge
    set_key US-0295 KFF-0295  # Clarks River National Wildlife Refuge
    set_key US-0296 KFF-0296  # Atchafalaya National Wildlife Refuge
    set_key US-0297 KFF-0297  # Bayou Cocodrie National Wildlife Refuge
    set_key US-0298 KFF-0298  # Bayou Sauvage National Wildlife Refuge
    set_key US-0299 KFF-0299  # Bayou Teche National Wildlife Refuge
    set_key US-0300 KFF-0300  # Big Branch Marsh National Wildlife Refuge
    set_key US-0301 KFF-0301  # Black Bayou Lake National Wildlife Refuge
    set_key US-0302 NIL-0000  # Bogue Chitto National Wildlife Refuge (MS); WWFF candidates: KFF-0302, KFF-4624
    set_key US-0303 KFF-0303  # Breton National Wildlife Refuge
    set_key US-0304 KFF-0304  # Cameron Praire National Wildlife Refuge
    set_key US-0305 KFF-0305  # Cat Island National Wildlife Refuge
    set_key US-0306 KFF-0306  # Catahoula National Wildlife Refuge
    set_key US-0307 KFF-0307  # D'Arbonne National Wildlife Refuge
    set_key US-0308 KFF-0308  # Delta National Wildlife Refuge
    set_key US-0309 KFF-0309  # Grand Cote National Wildlife Refuge
    set_key US-0310 KFF-0310  # Handy Brake National Wildlife Refuge
    set_key US-0311 KFF-0311  # Lacassine National Wildlife Refuge
    set_key US-0312 KFF-0312  # Lake Ophelia National Wildlife Refuge
    set_key US-0313 KFF-0313  # Louisiana Wetland Management District
    set_key US-0314 KFF-0314  # Mandalay National Wildlife Refuge
    set_key US-0315 KFF-0315  # Red River National Wildlife Refuge
    set_key US-0316 KFF-0316  # Sabine National Wildlife Refuge
    set_key US-0318 KFF-0318  # Tensas River National Wildlife Refuge
    set_key US-0319 KFF-0319  # Upper Ouachita National Wildlife Refuge
    set_key US-0320 KFF-0320  # Assabet River National Wildlife Refuge
    set_key US-0321 KFF-0321  # Great Meadows National Wildlife Refuge
    set_key US-0322 KFF-0322  # Mashpee National Wildlife Refuge
    set_key US-0324 KFF-0324  # Monomoy National Wildlife Refuge
    set_key US-0325 KFF-0325  # Nantucket National Wildlife Refuge
    set_key US-0327 KFF-0327  # Oxbow National Wildlife Refuge
    set_key US-0328 KFF-0328  # Parker River National Wildlife Refuge
    set_key US-0329 NIL-0000  # Silvio O Conte National Wildlife Refuge (NH); WWFF candidates: KFF-0329, KFF-4615, KFF-4616, KFF-4617
    set_key US-0330 KFF-0330  # Thatcher Island National Wildlife Refuge
    set_key US-0331 KFF-0331  # Blackwater National Wildlife Refuge
    set_key US-0332 KFF-0332  # Eastern Neck National Wildlife Refuge
    set_key US-0333 KFF-0333  # Martin National Wildlife Refuge
    set_key US-0334 KFF-0334  # Patuxent National Wildlife Refuge
    set_key US-0335 KFF-0335  # Susquehanna National Wildlife Refuge
    set_key US-0336 KFF-0336  # Aroostook National Wildlife Refuge
    set_key US-0337 KFF-0337  # Carlton Pond Wetland Management District
    set_key US-0338 KFF-0338  # Cross Island National Wildlife Refuge
    set_key US-0339 KFF-0339  # Franklin Island National Wildlife Refuge
    set_key US-0340 KFF-6855  # Spring Creek Hatchery State Park
    set_key US-0341 KFF-0341  # Moosehorn National Wildlife Refuge
    set_key US-0342 KFF-0342  # Pond Island National Wildlife Refuge
    set_key US-0343 KFF-0343  # Rachel Carson National Wildlife Refuge
    set_key US-0344 KFF-0344  # Seal Island National Wildlife Refuge
    set_key US-0345 KFF-0345  # Sunkhaze Meadows National Wildlife Refuge
    set_key US-0346 KFF-0346  # Detroit River National Wildlife Refuge
    set_key US-0347 KFF-0347  # Harbor Island National Wildlife Refuge
    set_key US-0348 KFF-0348  # Huron National Wildlife Refuge
    set_key US-0349 KFF-0349  # Kirtlands Warbler Wildlife Management Area
    set_key US-0350 KFF-0350  # Schlee Waterfowl Production Area
    set_key US-0352 KFF-0352  # Seney National Wildlife Refuge
    set_key US-0353 KFF-0353  # Shiawassee National Wildlife Refuge
    set_key US-0354 KFF-0354  # Agassiz National Wildlife Refuge
    set_key US-0355 KFF-0355  # Big Stone National Wildlife Refuge
    set_key US-0356 KFF-0356  # Big Stone Wetland Management District
    set_key US-0357 KFF-0357  # Crane Meadows National Wildlife Refuge
    set_key US-0358 KFF-0358  # Detroit Lakes Wetland Management District
    set_key US-0359 KFF-0359  # Fergus Falls Wetland Management District
    set_key US-0360 KFF-0360  # Glacial Ridge National Wildlife Refuge
    set_key US-0361 KFF-0361  # Hamden Slough National Wildlife Refuge
    set_key US-0362 KFF-0362  # Litchfield Wetland Management District
    set_key US-0364 KFF-0364  # Minnesota Valley National Wildlife Refuge
    set_key US-0365 KFF-0365  # Minnesota Valley Wetland Management District
    set_key US-0366 KFF-0366  # Morris Wetland Management District
    set_key US-0367 KFF-0367  # Northern Tallgrass Prairie National Wildlife Refuge
    set_key US-0368 KFF-0368  # Rice Lake National Wildlife Refuge
    set_key US-0369 KFF-0369  # Rydell National Wildlife Refuge
    set_key US-0370 KFF-0370  # Sherburne National Wildlife Refuge
    set_key US-0371 KFF-0371  # Tamarac National Wildlife Refuge
    set_key US-0373 KFF-0373  # Windom Wetland Management District
    set_key US-0374 KFF-0374  # Big Muddy National Wildlife Refuge
    set_key US-0375 KFF-0375  # Clarence Cannon National Wildlife Refuge
    set_key US-0376 KFF-0376  # Great River National Wildlife Refuge
    set_key US-0377 KFF-0377  # Mingo National Wildlife Refuge
    set_key US-0378 KFF-6853  # Miller Peninsula State Park
    set_key US-0380 KFF-0380  # Squaw Creek National Wildlife Refuge
    set_key US-0381 KFF-0381  # Swan Lake National Wildlife Refuge
    set_key US-0382 KFF-0382  # Coldwater River National Wildlife Refuge
    set_key US-0383 KFF-0383  # Dahomey National Wildlife Refuge
    set_key US-0384 NIL-0000  # Grand Bay (AL) National Wildlife Refuge; WWFF candidates: KFF-0384, KFF-7009
    set_key US-0385 KFF-0385  # Hillside National Wildlife Refuge
    set_key US-0386 KFF-0386  # Holt Collier National Wildlife Refuge
    set_key US-0387 KFF-0387  # Mathews Brake National Wildlife Refuge
    set_key US-0388 KFF-0388  # Mississippi Sandhill Crane National Wildlife Refuge
    set_key US-0389 KFF-0389  # Morgan Brake National Wildlife Refuge
    set_key US-0390 KFF-0390  # Noxubee National Wildlife Refuge
    set_key US-0391 KFF-0391  # Panther Swamp National Wildlife Refuge
    set_key US-0392 KFF-0392  # St. Catherine Creek National Wildlife Refuge
    set_key US-0393 KFF-0393  # Tallahatchie National Wildlife Refuge
    set_key US-0395 KFF-0395  # Yazoo National Wildlife Refuge
    set_key US-0396 KFF-0396  # Benton Lake National Wildlife Refuge
    set_key US-0397 KFF-0397  # Benton Lake Wetland Management District
    set_key US-0398 KFF-0398  # Bowdoin National Wildlife Refuge
    set_key US-0399 KFF-0399  # Charles M. Russell National Wildlife Refuge
    set_key US-0400 KFF-0400  # Halfbreed Lake National Wildlife Refuge
    set_key US-0401 KFF-0401  # Lake Mason National Wildlife Refuge
    set_key US-0402 KFF-0402  # Lee Metcalf National Wildlife Refuge
    set_key US-0403 KFF-0403  # Lost Trail National Wildlife Refuge
    set_key US-0404 KFF-0404  # Medicine Lake National Wildlife Refuge
    set_key US-0405 KFF-0405  # National Bison Range National Wildlife Refuge
    set_key US-0406 KFF-0406  # Northwest Montana Wetland Management District
    set_key US-0407 KFF-0407  # Red Rock Lakes National Wildlife Refuge
    set_key US-0408 KFF-0408  # UL Bend National Wildlife Refuge
    set_key US-0409 KFF-0409  # War Horse National Wildlife Refuge
    set_key US-0410 KFF-0410  # Alligator River National Wildlife Refuge
    set_key US-0411 KFF-0411  # Cedar Island National Wildlife Refuge
    set_key US-0412 KFF-0412  # Currituck National Wildlife Refuge
    set_key US-0413 KFF-0413  # Mackay Island National Wildlife Refuge
    set_key US-0414 KFF-0414  # Mattamuskeet National Wildlife Refuge
    set_key US-0415 KFF-0415  # Pea Island National Wildlife Refuge
    set_key US-0416 KFF-0416  # Pee Dee National Wildlife Refuge
    set_key US-0417 KFF-0417  # Pocosin Lakes National Wildlife Refuge
    set_key US-0418 KFF-0418  # Roanoke River National Wildlife Refuge
    set_key US-0419 KFF-0419  # Swanquarter National Wildlife Refuge
    set_key US-0420 KFF-0420  # Arrowwood National Wildlife Refuge
    set_key US-0421 KFF-0421  # Arrowwood Wetland Management District
    set_key US-0422 KFF-0422  # Audubon National Wildlife Refuge
    set_key US-0423 KFF-0423  # Chase Lake National Wildlife Refuge
    set_key US-0424 KFF-0424  # Des Lacs National Wildlife Refuge
    set_key US-0425 KFF-0425  # Devils Lake Wetland Management District
    set_key US-0426 KFF-0426  # Florence Lake National Wildlife Refuge
    set_key US-0427 KFF-0427  # J. Clark Salyer National Wildlife Refuge
    set_key US-0428 KFF-0428  # J. Clark Salyer Wetland Management District
    set_key US-0429 KFF-0429  # Kellys Slough National Wildlife Refuge
    set_key US-0430 KFF-0430  # Kulm Wetland Management District
    set_key US-0431 KFF-0431  # Lake Alice National Wildlife Refuge
    set_key US-0432 KFF-0432  # Lake Ilo National Wildlife Refuge
    set_key US-0433 KFF-0433  # Lake Zahl National Wildlife Refuge
    set_key US-0434 KFF-0434  # Long Lake National Wildlife Refuge
    set_key US-0435 KFF-0435  # Lostwood National Wildlife Refuge
    set_key US-0436 KFF-0436  # Slade National Wildlife Refuge
    set_key US-0437 KFF-0437  # Sullys Hill National Game Preserve
    set_key US-0438 KFF-0438  # Tewaukon National Wildlife Refuge
    set_key US-0439 KFF-0439  # Upper Souris National Wildlife Refuge
    set_key US-0440 KFF-0440  # Valley City Wetland Management District
    set_key US-0441 KFF-0441  # Boyer Chute National Wildlife Refuge
    set_key US-0442 KFF-0442  # Crescent Lake National Wildlife Refuge
    set_key US-0443 KFF-0443  # Fort Niobrara National Wildlife Refuge
    set_key US-0445 KFF-0445  # North Platte National Wildlife Refuge
    set_key US-0446 KFF-0446  # Rainwater Basin Wetland Management District
    set_key US-0447 KFF-0447  # Valentine National Wildlife Refuge
    set_key US-0448 KFF-0448  # Great Bay National Wildlife Refuge
    set_key US-0449 KFF-0449  # John Hay National Wildlife Refuge
    set_key US-0450 KFF-0450  # Lake Umbagog National Wildlife Refuge
    set_key US-0451 KFF-0451  # Wapack National Wildlife Refuge
    set_key US-0452 KFF-0452  # Cape May National Wildlife Refuge
    set_key US-0453 KFF-0453  # Edwin B. Forsythe National Wildlife Refuge
    set_key US-0454 KFF-0454  # Great Swamp National Wildlife Refuge
    set_key US-0455 KFF-0455  # Supawna Meadows National Wildlife Refuge
    set_key US-0456 NIL-0000  # Wallkill River (NY) National Wildlife Refuge; WWFF candidates: KFF-0456, KFF-7504
    set_key US-0457 KFF-0457  # Bitter Lake National Wildlife Refuge
    set_key US-0458 KFF-0458  # Bosque Del Apache National Wildlife Refuge
    set_key US-0459 KFF-0459  # Las Vegas National Wildlife Refuge
    set_key US-0460 KFF-0460  # Maxwell National Wildlife Refuge
    set_key US-0461 KFF-0461  # San Andres National Wildlife Refuge
    set_key US-0462 KFF-0462  # Sevilleta National Wildlife Refuge
    set_key US-0463 KFF-0463  # Anaho Island National Wildlife Refuge
    set_key US-0464 KFF-0464  # Ash Meadows National Wildlife Refuge
    set_key US-0465 KFF-0465  # Desert National Wildlife Refuge
    set_key US-0466 KFF-0466  # Fallon National Wildlife Refuge
    set_key US-0467 KFF-0467  # Moapa Valley National Wildlife Refuge
    set_key US-0468 KFF-0468  # Pahranagat National Wildlife Refuge
    set_key US-0469 KFF-0469  # Ruby Lake National Wildlife Refuge
    set_key US-0470 KFF-0470  # Sheldon National Wildlife Refuge
    set_key US-0471 KFF-0471  # Stillwater National Wildlife Refuge
    set_key US-0472 KFF-0472  # Amagansett National Wildlife Refuge
    set_key US-0473 KFF-0473  # Conscience Point National Wildlife Refuge
    set_key US-0474 KFF-0474  # Elizabeth A. Morton National Wildlife Refuge
    set_key US-0475 KFF-0475  # Iroquois National Wildlife Refuge
    set_key US-0476 KFF-0476  # Montezuma National Wildlife Refuge
    set_key US-0477 KFF-0477  # Congressman Lester Wolff Oyster Bay National Wildlife Refuge
    set_key US-0478 KFF-0478  # Seatuck National Wildlife Refuge
    set_key US-0479 KFF-0479  # Shawangunk Grasslands National Wildlife Refuge
    set_key US-0480 KFF-0480  # Target Rock National Wildlife Refuge
    set_key US-0481 KFF-0481  # Wertheim National Wildlife Refuge
    set_key US-0482 KFF-0482  # Cedar Point National Wildlife Refuge
    set_key US-0483 KFF-0483  # Ottawa National Wildlife Refuge
    set_key US-0485 KFF-0485  # Deep Fork National Wildlife Refuge
    set_key US-0486 KFF-0486  # Little River National Wildlife Refuge
    set_key US-0487 KFF-0487  # Optima National Wildlife Refuge
    set_key US-0488 KFF-0488  # Ozark Plateau National Wildlife Refuge
    set_key US-0489 KFF-0489  # Salt Plains National Wildlife Refuge
    set_key US-0490 KFF-0490  # Sequoyah National Wildlife Refuge
    set_key US-0491 KFF-0491  # Tishomingo National Wildlife Refuge
    set_key US-0492 KFF-0492  # Washita National Wildlife Refuge
    set_key US-0493 KFF-0493  # Wichita Mountains National Wildlife Refuge
    set_key US-0494 KFF-0494  # Ankeny National Wildlife Refuge
    set_key US-0495 KFF-0495  # Bandon Marsh National Wildlife Refuge
    set_key US-0496 KFF-0496  # Baskett Slough National Wildlife Refuge
    set_key US-0497 KFF-0497  # Bear Valley National Wildlife Refuge
    set_key US-0498 KFF-0498  # Cape Meares National Wildlife Refuge
    set_key US-0499 KFF-0499  # Cold Springs National Wildlife Refuge
    set_key US-0500 KFF-0500  # Hart Mountain National Wildlife Refuge
    set_key US-0501 KFF-0501  # Klamath Marsh National Wildlife Refuge
    set_key US-0502 KFF-0502  # Malheur National Wildlife Refuge
    set_key US-0503 KFF-0503  # McKay Creek National Wildlife Refuge
    set_key US-0504 KFF-0504  # Nestucca Bay National Wildlife Refuge
    set_key US-0505 KFF-0505  # Oregon Islands National Wildlife Refuge
    set_key US-0506 KFF-0506  # Siletz Bay National Wildlife Refuge
    set_key US-0507 KFF-0507  # Three Arch Rocks National Wildlife Refuge
    set_key US-0508 KFF-0508  # Tualatin River National Wildlife Refuge
    set_key US-0509 KFF-0509  # Upper Klamath National Wildlife Refuge
    set_key US-0510 KFF-0510  # William L. Finley National Wildlife Refuge
    set_key US-0511 KFF-0511  # Erie National Wildlife Refuge
    set_key US-0512 KFF-0512  # John Heinz National Wildlife Refuge
    set_key US-0513 KFF-0513  # Block Island National Wildlife Refuge
    set_key US-0514 KFF-0514  # John H. Chafee National Wildlife Refuge
    set_key US-0515 KFF-0515  # Ninigret National Wildlife Refuge
    set_key US-0516 KFF-0516  # Sachuest Point National Wildlife Refuge
    set_key US-0517 KFF-0517  # Trustom Pond National Wildlife Refuge
    set_key US-0518 KFF-0518  # Cape Romain National Wildlife Refuge
    set_key US-0519 KFF-0519  # Carolina Sandhills National Wildlife Refuge
    set_key US-0520 KFF-0520  # Ernest F. Hollings ACE Basin National Wildlife Refuge
    set_key US-0521 KFF-0521  # Santee National Wildlife Refuge
    set_key US-0522 NIL-0000  # Savannah National Wildlife Refuge (SC); WWFF candidates: KFF-0522, KFF-4712
    set_key US-0524 KFF-0524  # Waccamaw National Wildlife Refuge
    set_key US-0525 KFF-0525  # Huron Wetland Management District
    set_key US-0527 KFF-0527  # Lacreek National Wildlife Refuge
    set_key US-0528 KFF-0528  # Lake Andes National Wildlife Refuge
    set_key US-0529 KFF-0529  # Madison Wetland Management District
    set_key US-0530 KFF-0530  # Sand Lake National Wildlife Refuge
    set_key US-0531 KFF-0531  # Waubay National Wildlife Refuge
    set_key US-0532 KFF-0532  # Waubay Wetland Management District
    set_key US-0533 KFF-0533  # Chickasaw National Wildlife Refuge
    set_key US-0534 KFF-0534  # Cross Creek National Wildlife Refuge
    set_key US-0535 KFF-0535  # Hatchie National Wildlife Refuge
    set_key US-0536 KFF-0536  # Lake Isom National Wildlife Refuge
    set_key US-0537 KFF-0537  # Lower Hatchie National Wildlife Refuge
    set_key US-0538 KFF-0538  # Reelfoot National Wildlife Refuge
    set_key US-0539 KFF-0539  # Tennessee National Wildlife Refuge
    set_key US-0540 KFF-0540  # Anahuac National Wildlife Refuge
    set_key US-0541 KFF-0541  # Aransas National Wildlife Refuge
    set_key US-0542 KFF-0542  # Attwater Prairie Chicken National Wildlife Refuge
    set_key US-0543 KFF-0543  # Balcones Canyonlands National Wildlife Refuge
    set_key US-0544 KFF-0544  # Big Boggy National Wildlife Refuge
    set_key US-0545 KFF-0545  # Brazoria National Wildlife Refuge
    set_key US-0546 KFF-0546  # Buffalo Lake National Wildlife Refuge
    set_key US-0547 KFF-0547  # Grulla National Wildlife Refuge
    set_key US-0548 KFF-0548  # Hagerman National Wildlife Refuge
    set_key US-0549 KFF-0549  # Laguna Atascosa National Wildlife Refuge
    set_key US-0550 KFF-0550  # Lower Rio Grande Valley National Wildlife Refuge
    set_key US-0551 KFF-0551  # McFaddin National Wildlife Refuge
    set_key US-0552 KFF-0552  # Muleshoe National Wildlife Refuge
    set_key US-0553 KFF-0553  # San Bernard National Wildlife Refuge
    set_key US-0554 KFF-0554  # Santa Ana National Wildlife Refuge
    set_key US-0555 KFF-0555  # Texas Point National Wildlife Refuge
    set_key US-0556 KFF-0556  # Trinity River National Wildlife Refuge
    set_key US-0557 KFF-0557  # Bear River National Wildlife Refuge
    set_key US-0558 KFF-0558  # Fish Springs National Wildlife Refuge
    set_key US-0559 KFF-0559  # Ouray National Wildlife Refuge
    set_key US-0560 KFF-0560  # Back Bay National Wildlife Refuge
    set_key US-0561 KFF-0561  # Chincoteague National Wildlife Refuge
    set_key US-0562 KFF-0562  # Eastern Shore of Virginia National Wildlife Refuge
    set_key US-0563 KFF-0563  # Elizabeth Hartwell Mason Neck National Wildlife Refuge
    set_key US-0564 KFF-0564  # Featherstone National Wildlife Refuge
    set_key US-0565 KFF-0565  # Fisherman Island National Wildlife Refuge
    set_key US-0566 KFF-0566  # Great Dismal Swamp National Wildlife Refuge
    set_key US-0567 KFF-0567  # James River National Wildlife Refuge
    set_key US-0569 KFF-0569  # Occoquan Bay National Wildlife Refuge
    set_key US-0572 KFF-0572  # Rappahannock River Valley National Wildlife Refuge
    set_key US-0573 KFF-0573  # Wallops Island National Wildlife Refuge
    set_key US-0574 KFF-0574  # Missisquoi National Wildlife Refuge
    set_key US-0575 KFF-0575  # Columbia National Wildlife Refuge
    set_key US-0576 KFF-0576  # Conboy Lake National Wildlife Refuge
    set_key US-0577 KFF-7438  # Clinch River State Park
    set_key US-0578 KFF-0578  # Dungeness National Wildlife Refuge
    set_key US-0580 KFF-0580  # Franz Lake National Wildlife Refuge
    set_key US-0581 KFF-0581  # Grays Harbor National Wildlife Refuge
    set_key US-0582 KFF-0582  # Julia Butler Hansen National Wildlife Refuge
    set_key US-0583 KFF-0583  # Lewis and Clark National Wildlife Refuge
    set_key US-0584 KFF-0584  # Little Pend Oreille National Wildlife Refuge
    set_key US-0585 KFF-0585  # Mcnary National Wildlife Refuge
    set_key US-0586 KFF-0586  # Billy Frank Jr. Nisqually National Wildlife Refuge
    set_key US-0590 KFF-0590  # Ridgefield National Wildlife Refuge
    set_key US-0591 KFF-0591  # Saddle Mountain National Wildlife Refuge
    set_key US-0592 KFF-0592  # San Juan Islands National Wildlife Refuge
    set_key US-0593 KFF-0593  # Steigerwald Lake National Wildlife Refuge
    set_key US-0594 KFF-0594  # Toppenish National Wildlife Refuge
    set_key US-0595 KFF-0595  # Turnbull National Wildlife Refuge
    set_key US-0596 NIL-0000  # Umatilla National Wildlife Refuge (OR); WWFF candidates: KFF-0596, KFF-4598
    set_key US-0597 KFF-0597  # Willapa National Wildlife Refuge
    set_key US-0598 KFF-0598  # Fox River National Wildlife Refuge
    set_key US-0599 KFF-0599  # Gravel Island National Wildlife Refuge
    set_key US-0600 NIL-0000  # Green Bay National Wildlife Refuge (MI); WWFF candidates: KFF-0600, KFF-4625
    set_key US-0601 KFF-0601  # Horicon National Wildlife Refuge
    set_key US-0602 KFF-0602  # Leopold Wetland Management District
    set_key US-0603 KFF-0603  # Necedah National Wildlife Refuge
    set_key US-0604 KFF-0604  # St. Croix Wetland Management District
    set_key US-0605 KFF-0605  # Trempealeau National Wildlife Refuge
    set_key US-0606 KFF-0606  # Whittlesey Creek National Wildlife Refuge
    set_key US-0607 KFF-0607  # Canaan Valley National Wildlife Refuge
    set_key US-0608 KFF-0608  # Ohio River Islands
    set_key US-0609 KFF-0609  # Bamforth National Wildlife Refuge
    set_key US-0610 KFF-0610  # Cokeville Meadows National Wildlife Refuge
    set_key US-0611 KFF-0611  # Hutton Lake National Wildlife Refuge
    set_key US-0612 KFF-0612  # Mortenson Lake National Wildlife Refuge
    set_key US-0613 KFF-0613  # National Elk National Wildlife Refuge
    set_key US-0614 KFF-0614  # Pathfinder National Wildlife Refuge
    set_key US-0615 KFF-0615  # Seedskadee National Wildlife Refuge
    set_key US-0619 KFF-0619  # Allegheny National Forest
    set_key US-0620 KFF-0620  # Beechwood Farms State Conservation Area
    set_key US-0621 KFF-0621  # Todd Sanctuary State Conservation Area
    set_key US-0622 KFF-0622  # Bear Run State Conservation Area
    set_key US-0623 KFF-0623  # Powdermill State Conservation Area
    set_key US-0624 KFF-0624  # Roaring Run State Natural Area
    set_key US-0625 KFF-0625  # Mount Davis State Natural Area
    set_key US-0626 KFF-0626  # Sweet Root State Natural Area
    set_key US-0627 KFF-0627  # Pine Ridge State Natural Area
    set_key US-0628 KFF-0628  # Charles F. Lewis State Natural Area
    set_key US-0629 KFF-0629  # Tomlinson Run State Park
    set_key US-0630 KFF-0630  # Coopers Rock State Park
    set_key US-0631 KFF-0631  # Cathedral State Park
    set_key US-0632 KFF-0632  # Monongahela National Forest
    set_key US-0633 KFF-0633  # Caddo Lake National Wildlife Refuge
    set_key US-0634 KFF-0634  # Little Talbot State Park
    set_key US-0635 KFF-0635  # St. George State Park
    set_key US-0636 KFF-0636  # Jekyll Island State Park
    set_key US-0637 KFF-0637  # Mills Park State Conservation Area
    set_key US-0638 KFF-0638  # Lorance Creek Natural Area
    set_key US-0639 KFF-0639  # Los Padres National Forest
    set_key US-0640 KFF-0640  # Pinnacles National Park
    set_key US-0641 KFF-0641  # Little River Canyon National Conservation Area
    set_key US-0642 NIL-0000  # Natchez Trace Parkway National Parkway (TN); WWFF candidates: KFF-0642, KFF-5629, KFF-5630
    set_key US-0643 KFF-0643  # Noatak National Preserve
    set_key US-0644 KFF-0644  # Bering Land Bridge National Preserve
    set_key US-0645 NIL-0000  # Glen Canyon National Recreation Area (AZ); WWFF candidates: KFF-0645, KFF-4618
    set_key US-0646 KFF-6937  # Buffalo National Wild and Scenic River
    set_key US-0647 KFF-0647  # Golden Gate National Recreation Area
    set_key US-0648 KFF-0648  # Santa Monica Mountains National Recreation Area
    set_key US-0649 KFF-0649  # Whiskeytown-Shasta-Trinity National Recreation Area
    set_key US-0650 KFF-0650  # Mojave Preserve National Conservation Area
    set_key US-0651 KFF-0651  # Point Reyes National Seashore
    set_key US-0652 KFF-0652  # Curecanti National Recreation Area
    set_key US-0653 KFF-0653  # Constitution Gardens National Park
    set_key US-0654 KFF-0654  # National Capital Parks Park
    set_key US-0655 KFF-0655  # National Mall Park
    set_key US-0656 KFF-0656  # Rock Creek Park
    set_key US-0657 KFF-0657  # President's Park (White House) Park
    set_key US-0658 KFF-0658  # Timucuan Preserve National Conservation Area
    set_key US-0659 KFF-0659  # Big Cypress National Preserve
    set_key US-0660 KFF-0660  # Canaveral National Seashore
    set_key US-0661 NIL-0000  # Gulf Islands National Seashore (MS); WWFF candidates: KFF-0661, KFF-4621
    set_key US-0662 KFF-0662  # Chattahoochee River National Recreation Area
    set_key US-0663 KFF-0663  # Cumberland Island National Seashore
    set_key US-0664 KFF-0664  # City of Rocks Reserve National Conservation Area
    set_key US-0665 KFF-0665  # Craters of the Moon National Monument
    set_key US-0666 KFF-0666  # Catoctin Mountain Park
    set_key US-0667 KFF-0667  # Fort Washington Park
    set_key US-0668 KFF-0668  # Greenbelt Park
    set_key US-0669 KFF-0669  # Piscataway Park
    set_key US-0670 NIL-0000  # George Washington Memorial Parkway (DofC); WWFF candidates: KFF-0670, KFF-4585
    set_key US-0671 NIL-0000  # Assateague Island National Seashore (VA); WWFF candidates: KFF-0671, KFF-4591
    set_key US-0672 KFF-0672  # Cape Cod National Seashore
    set_key US-0673 KFF-0673  # Saint Croix National Wild and Scenic River (MN)
    set_key US-0674 KFF-0674  # Bighorn Canyon National Recreation Area
    set_key US-0675 KFF-0675  # Missouri National Wild and Scenic River (NE)
    set_key US-0676 NIL-0000  # Lake Mead (AZ) National Recreation Area; WWFF candidates: KFF-0676, KFF-7448
    set_key US-0677 KFF-0677  # Great Egg Harbor National Wild and Scenic River
    set_key US-0678 KFF-0678  # Valles Caldera Preserve National Conservation Area
    set_key US-0679 KFF-0679  # Fire Island National Seashore
    set_key US-0680 NIL-0000  # Gateway National Recreation Area (NJ); WWFF candidates: KFF-0680, KFF-4594
    set_key US-0681 NIL-0000  # Upper Delaware National Wild and Scenic River (NY); WWFF candidates: KFF-0681, KFF-4596
    set_key US-0682 KFF-0682  # Cape Hatteras National Seashore
    set_key US-0683 KFF-0683  # Cape Lookout National Seashore
    set_key US-0684 NIL-0000  # Lower Delaware National Wild and Scenic River (PA); WWFF candidates: KFF-0684, KFF-4593
    set_key US-0685 KFF-0685  # Obed National Wild and Scenic River
    set_key US-0686 KFF-0686  # Big South Fork National Wild and Scenic River (TN)
    set_key US-0687 KFF-0687  # Amistad National Recreation Area
    set_key US-0688 KFF-0688  # Lake Meredith National Recreation Area
    set_key US-0689 KFF-0689  # Big Thicket Preserve National Conservation Area
    set_key US-0690 KFF-0690  # Padre Island National Seashore
    set_key US-0691 KFF-0691  # Prince William Forest Park
    set_key US-0692 KFF-0692  # Wolf Trap National Park
    set_key US-0693 KFF-0693  # Ross Lake National Recreation Area
    set_key US-0694 KFF-0694  # Ebey's Landing Reserve National Conservation Area
    set_key US-0695 KFF-0695  # Gauley River National Recreation Area
    set_key US-0696 KFF-0696  # New River Gorge National Park
    set_key US-0697 KFF-0697  # Bluestone National Wild and Scenic River
    set_key US-0698 KFF-0698  # John D. Rockefeller Jr. National Parkway
    set_key US-0699 KFF-0699  # Lake Roosevelt National Recreation Area
    set_key US-0700 KFF-0700  # Antietam National Battlefield
    set_key US-0701 KFF-0701  # Big Hole National Battlefield
    set_key US-0702 KFF-0702  # Cowpens National Battlefield
    set_key US-0703 KFF-0703  # Fort Donelson National Battlefield (TN)
    set_key US-0704 KFF-0704  # Fort Necessity National Battlefield
    set_key US-0705 KFF-0705  # Monocacy National Battlefield
    set_key US-0706 KFF-0706  # Moores Creek National Battlefield
    set_key US-0707 KFF-0707  # Petersburg National Battlefield
    set_key US-0708 KFF-0708  # Stones River National Battlefield
    set_key US-0709 KFF-0709  # Tupelo National Battlefield
    set_key US-0710 KFF-0710  # Wilson's Creek National Battlefield
    set_key US-0711 KFF-0711  # Kennesaw Mountain National Battlefield
    set_key US-0712 KFF-0712  # Manassas National Battlefield
    set_key US-0713 KFF-0713  # Richmond National Battlefield
    set_key US-0714 KFF-0714  # River Raisin National Battlefield
    set_key US-0715 KFF-0715  # Brices Cross Roads National Battlefield
    set_key US-0716 KFF-0716  # Chickamauga and Chattanooga National Military Park (TN)
    set_key US-0717 KFF-0717  # Fredericksburg and Spotsylvania National Military Park
    set_key US-0718 KFF-0718  # Guilford Courthouse National Military Park
    set_key US-0719 KFF-0719  # Horseshoe Bend National Military Park
    set_key US-0720 KFF-0720  # Kings Mountain National Military Park
    set_key US-0721 KFF-0721  # Pea Ridge National Military Park
    set_key US-0722 KFF-0722  # Shiloh National Battlefield (TN)
    set_key US-0723 KFF-0723  # Vicksburg National Military Park
    set_key US-0724 KFF-0724  # Abraham Lincoln Birthplace National Historic Site
    set_key US-0726 KFF-0726  # Appomattox Court House National Historical Park
    set_key US-0727 KFF-6098  # Lake Lenore Caves State Park
    set_key US-0728 KFF-0728  # Boston National Historical Park
    set_key US-0729 KFF-0729  # Cane River Creole National Historical Park
    set_key US-0730 KFF-0730  # Cedar Creek and Belle Grove National Historical Park
    set_key US-0731 NIL-0000  # Columbia River Gorge National Scenic Area (WA); WWFF candidates: KFF-6746, KFF-6750
    set_key US-0732 KFF-0732  # Dayton Aviation Heritage National Historical Park
    set_key US-0733 KFF-0733  # First State National Historical Park
    set_key US-0734 KFF-0734  # George Rogers Clark National Historical Park
    set_key US-0735 NIL-0000  # Harpers Ferry National Historical Park (VA); WWFF candidates: KFF-0735, KFF-4588, KFF-4589
    set_key US-0736 KFF-0736  # Harriet Tubman Underground Railroad National Historical Park
    set_key US-0737 KFF-0737  # Hopewell Culture National Historical Park
    set_key US-0738 KFF-0738  # Independence National Historical Park
    set_key US-0739 KFF-0739  # Kaloko-Honokohau National Historical Park
    set_key US-0740 KFF-0740  # Keweenaw National Historical Park
    set_key US-0742 KFF-0742  # Lowell National Historical Park
    set_key US-0743 KFF-0743  # Lyndon B. Johnson National Historical Park
    set_key US-0744 KFF-0744  # Marsh-Billings-Rockefeller National Historical Park
    set_key US-0745 KFF-0745  # Minute Man National Historical Park
    set_key US-0746 KFF-0746  # Morristown National Historical Park
    set_key US-0747 KFF-0747  # Natchez National Historical Park
    set_key US-0748 KFF-0748  # New Bedford Whaling National Historical Park
    set_key US-0749 KFF-0749  # New Orleans Jazz National Historical Park
    set_key US-0750 KFF-0750  # Palo Alto Battlefield National Historic Site
    set_key US-0751 KFF-0751  # Paterson Great Falls National Historical Park
    set_key US-0752 KFF-0752  # Pecos National Historical Park
    set_key US-0753 KFF-0753  # Pu'uhonua o Honaunau National Historical Park
    set_key US-0754 KFF-0754  # Rosie the Riveter WWII Home Front National Historical Park
    set_key US-0756 KFF-0756  # San Antonio Missions National Historical Park
    set_key US-0757 KFF-0757  # San Francisco Maritime National Historical Park
    set_key US-0758 KFF-0758  # Sitka National Historical Park
    set_key US-0759 KFF-0759  # Thomas Edison National Historical Park
    set_key US-0760 KFF-0760  # Tumacacori National Historical Park
    set_key US-0761 KFF-0761  # Valley Forge National Historical Park
    set_key US-0763 KFF-0763  # Women's Rights National Historical Park
    set_key US-0764 KFF-0764  # Apostle Islands National Lakeshore
    set_key US-0765 KFF-0765  # Indiana Dunes National Park
    set_key US-0766 KFF-0766  # Pictured Rocks National Lakeshore
    set_key US-0767 KFF-0767  # Sleeping Bear Dunes National Lakeshore
    set_key US-0768 KFF-0768  # Arkansas Post National Memorial
    set_key US-0770 KFF-0770  # Chamizal National Memorial
    set_key US-0771 KFF-0771  # Coronado National Memorial
    set_key US-0772 KFF-0772  # De Soto National Memorial
    set_key US-0773 KFF-0773  # Federal Hall National Memorial
    set_key US-0774 KFF-0774  # Flight 93 National Memorial
    set_key US-0775 KFF-0775  # Fort Caroline National Memorial
    set_key US-0776 KFF-0776  # Franklin Delano Roosevelt National Memorial
    set_key US-0777 KFF-0777  # General Grant National Memorial
    set_key US-0778 KFF-0778  # Hamilton Grange National Memorial
    set_key US-0779 KFF-0779  # Gateway Arch National Park
    set_key US-0780 KFF-0780  # Korean War Veterans National Memorial
    set_key US-0781 KFF-0781  # Johnstown Flood National Memorial
    set_key US-0782 KFF-0782  # Lincoln Boyhood Home National Memorial
    set_key US-0783 KFF-0783  # Lincoln National Memorial
    set_key US-0784 KFF-0784  # Lyndon Baines Johnson Memorial Grove on the Potomac National Memorial
    set_key US-0785 KFF-0785  # Martin Luther King Jr. National Memorial
    set_key US-0786 KFF-0786  # Mount Rushmore National Memorial
    set_key US-0787 KFF-0787  # Perry's Victory and International Peace National Memorial
    set_key US-0789 KFF-0789  # Roger Williams National Memorial
    set_key US-0790 KFF-0790  # Thaddeus Kosciuszko National Memorial
    set_key US-0791 KFF-0791  # Theodore Roosevelt Island National Memorial
    set_key US-0792 KFF-0792  # Thomas Jefferson National Memorial
    set_key US-0793 KFF-0793  # Vietnam Veterans National Memorial
    set_key US-0794 KFF-0794  # Washington Monument National Memorial
    set_key US-0795 KFF-0795  # World War I National Memorial
    set_key US-0796 KFF-0796  # World War II National Memorial
    set_key US-0797 KFF-0797  # Wright Brothers National Memorial
    set_key US-0798 KFF-0798  # Allegheny Portage Railroad National Historic Site
    set_key US-0799 KFF-0799  # Andersonville National Historic Site
    set_key US-0800 KFF-0800  # Andrew Johnson National Historic Site
    set_key US-0801 KFF-0801  # Bent's Old Fort National Historic Site
    set_key US-0802 KFF-0802  # Boston African American National Historic Site
    set_key US-0803 KFF-0803  # Brown vs. Board of Education National Historic Site
    set_key US-0804 KFF-0804  # Carl Sandburg National Historic Site
    set_key US-0805 KFF-0805  # Carter G. Woodson Home National Historic Site
    set_key US-0806 KFF-0806  # Charles Pinckney National Historic Site
    set_key US-0808 KFF-0808  # Clara Barton National Historic Site
    set_key US-0809 KFF-0809  # Edgar Allan Poe National Historic Site
    set_key US-0810 KFF-0810  # Eisenhower National Historic Site
    set_key US-0811 KFF-0811  # Eleanor Roosevelt National Historic Site
    set_key US-0812 KFF-0812  # Eugene O'Neill National Historic Site
    set_key US-0813 KFF-0813  # First Ladies National Historic Site
    set_key US-0814 KFF-0814  # Ford's Theatre National Historic Site
    set_key US-0815 KFF-0815  # Fort Bowie National Historic Site
    set_key US-0816 KFF-0816  # Fort Davis National Historic Site
    set_key US-0817 KFF-0817  # Fort Laramie National Historic Site
    set_key US-0818 KFF-0818  # Fort Larned National Historic Site
    set_key US-0819 KFF-0819  # Fort Point National Historic Site
    set_key US-0820 KFF-0820  # Fort Raleigh National Historic Site
    set_key US-0821 KFF-0821  # Fort Scott National Historic Site
    set_key US-0822 KFF-0822  # Fort Smith National Historic Site
    set_key US-0823 KFF-0823  # Fort Union Trading Post National Historic Site
    set_key US-0824 KFF-0824  # Fort Vancouver National Historic Site (WA)
    set_key US-0825 KFF-0825  # Frederick Douglass National Historic Site
    set_key US-0826 KFF-0826  # Frederick Law Olmsted National Historic Site
    set_key US-0827 KFF-0827  # Friendship Hill National Historic Site
    set_key US-0828 KFF-0828  # Golden Spike National Historical Park
    set_key US-0829 KFF-0829  # Grant-Kohrs Ranch National Historic Site
    set_key US-0830 KFF-0830  # Hampton National Historic Site
    set_key US-0831 KFF-0831  # Harry S. Truman National Historic Site
    set_key US-0832 KFF-0832  # Herbert Hoover National Historic Site
    set_key US-0833 KFF-0833  # Home of Franklin D. Roosevelt National Historic Site
    set_key US-0834 KFF-0834  # Hopewell Furnace National Historic Site
    set_key US-0835 KFF-0835  # Hubbell Trading Post National Historic Site
    set_key US-0836 KFF-0836  # James A. Garfield National Historic Site
    set_key US-0837 KFF-0837  # Jimmy Carter National Historic Site
    set_key US-0839 KFF-0839  # John Muir National Historic Site
    set_key US-0840 KFF-0840  # Knife River Indian Villages National Historic Site
    set_key US-0841 KFF-0841  # Lincoln Home National Historic Site
    set_key US-0842 KFF-0842  # Little Rock Central High School National Historic Site
    set_key US-0844 KFF-0844  # Maggie L. Walker National Historic Site
    set_key US-0845 KFF-0845  # Manzanar National Historic Site
    set_key US-0846 KFF-0846  # Martin Luther King Jr. National Historic Site
    set_key US-0847 KFF-0847  # Martin Van Buren National Historic Site
    set_key US-0848 KFF-0848  # Mary McLeod Bethune Council House National Historic Site
    set_key US-0849 KFF-0849  # Minidoka Internment National Historic Site
    set_key US-0850 KFF-0850  # Minuteman Missile National Historic Site
    set_key US-0851 KFF-0851  # Nicodemus National Historic Site
    set_key US-0852 KFF-0852  # Ninety Six National Historic Site
    set_key US-0853 KFF-0853  # Pennsylvania Avenue National Historic Site
    set_key US-0854 KFF-0854  # William Jefferson Clinton Birthplace National Historic Site
    set_key US-0856 KFF-0856  # Sagamore Hill National Historic Site
    set_key US-0857 KFF-0857  # Saint-Gaudens National Historic Site
    set_key US-0858 KFF-0858  # Saint Paul's Church National Historic Site
    set_key US-0859 KFF-0859  # Salem Maritime National Historic Site
    set_key US-0861 KFF-0861  # Sand Creek Massacre National Historic Site
    set_key US-0862 KFF-0862  # Saugus Iron Works National Historic Site
    set_key US-0863 KFF-0863  # Springfield Armory National Historic Site
    set_key US-0864 KFF-0864  # Steamtown National Historic Site
    set_key US-0865 KFF-0865  # Theodore Roosevelt Birthplace National Historic Site
    set_key US-0866 KFF-0866  # Theodore Roosevelt Inaugural National Historic Site
    set_key US-0867 KFF-0867  # Thomas Stone National Historic Site
    set_key US-0868 KFF-0868  # Tuskegee Airmen National Historic Site
    set_key US-0869 KFF-0869  # Tuskegee Institute National Historic Site
    set_key US-0870 KFF-0870  # Ulysses S. Grant National Historic Site
    set_key US-0871 KFF-0871  # Vanderbilt Mansion National Historic Site
    set_key US-0872 KFF-0872  # Washita Battlefield National Historic Site
    set_key US-0873 KFF-0873  # Weir Farm National Historic Site
    set_key US-0874 KFF-0874  # Whitman Mission National Historic Site
    set_key US-0875 KFF-0875  # William Howard Taft National Historic Site
    set_key US-0876 KFF-0876  # Manhattan Project National Historic Site
    set_key US-0877 KFF-0877  # Alatna National Wild and Scenic River
    set_key US-0878 KFF-0878  # Aniakchak National Wild and Scenic River
    set_key US-0879 KFF-0879  # Charley National Wild and Scenic River
    set_key US-0880 KFF-0880  # Chilikadrotna National Wild and Scenic River
    set_key US-0881 KFF-0881  # Eightmile National Wild and Scenic River
    set_key US-0882 KFF-0882  # Farmington National Wild and Scenic River
    set_key US-0883 KFF-0883  # Flathead National Wild and Scenic River
    set_key US-0884 KFF-0884  # Kings River National Wild and Scenic River
    set_key US-0885 KFF-0885  # Lamprey National Wild and Scenic River
    set_key US-0886 KFF-0886  # Maurice River National Wild and Scenic River
    set_key US-0887 KFF-0887  # Mulchatna National Wild and Scenic River
    set_key US-0888 KFF-0888  # Musconetcong River National Wild and Scenic River
    set_key US-0889 KFF-0889  # Noatak National Wild and Scenic River
    set_key US-0890 KFF-0890  # Salmon National Wild and Scenic River
    set_key US-0891 KFF-0891  # Taunton National Wild and Scenic River
    set_key US-0892 KFF-0892  # Tinayguk National Wild and Scenic River
    set_key US-0893 KFF-0893  # Tlikakila National Wild and Scenic River
    set_key US-0894 KFF-0894  # Tuolumne National Wild and Scenic River
    set_key US-0895 KFF-0895  # Virgin National Wild and Scenic River
    set_key US-0896 KFF-0896  # Wekiva National Wild and Scenic River
    set_key US-0897 KFF-0897  # Westfield National Wild and Scenic River
    set_key US-0898 NIL-0000  # White Clay Creek National Wild and Scenic River (DE); WWFF candidates: KFF-0898, KFF-4592
    set_key US-0899 KFF-0899  # African Burial Ground National Monument
    set_key US-0900 KFF-0900  # Agate Fossil Beds National Monument
    set_key US-0901 KFF-0901  # Alibates Flint Quarries National Monument
    set_key US-0902 KFF-0902  # Aniakchak National Monument
    set_key US-0903 KFF-0903  # Aztec Ruins National Monument
    set_key US-0904 KFF-0904  # Bandelier National Monument
    set_key US-0905 KFF-0905  # Booker T. Washington National Monument
    set_key US-0907 KFF-0907  # Cabrillo National Monument
    set_key US-0908 KFF-0908  # Canyon de Chelly National Monument
    set_key US-0909 KFF-0909  # Cape Krusenstern National Monument
    set_key US-0910 KFF-0910  # Capulin Volcano National Monument
    set_key US-0911 KFF-0911  # Casa Grande Ruins National Monument
    set_key US-0912 KFF-0912  # Castillo de San Marcos National Monument
    set_key US-0913 KFF-0913  # Castle Clinton National Monument
    set_key US-0914 KFF-0914  # Cedar Breaks National Monument
    set_key US-0915 KFF-0915  # Cesar E. Chavez National Monument
    set_key US-0916 KFF-0916  # Charles Young Buffalo Soldiers National Monument
    set_key US-0917 KFF-0917  # Chiricahua National Monument
    set_key US-0918 KFF-0918  # Colorado National Monument
    set_key US-0919 KFF-0919  # Devils Postpile National Monument
    set_key US-0920 KFF-0920  # Devils Tower National Monument
    set_key US-0921 NIL-0000  # Dinosaur National Monument (UT); WWFF candidates: KFF-0921, KFF-6749
    set_key US-0922 KFF-0922  # Effigy Mounds National Monument
    set_key US-0923 KFF-0923  # El Malpais National Monument
    set_key US-0924 KFF-0924  # El Morro National Monument
    set_key US-0925 KFF-0925  # Florissant Fossil Beds National Monument
    set_key US-0926 KFF-0926  # Fort Frederica National Monument
    set_key US-0927 KFF-0927  # Fort Matanzas National Monument
    set_key US-0928 KFF-0928  # Fort McHenry National Monument
    set_key US-0929 KFF-0929  # Fort Monroe National Monument
    set_key US-0930 KFF-0930  # Fort Pulaski National Monument
    set_key US-0931 KFF-0931  # Fort Stanwix National Monument
    set_key US-0932 KFF-0932  # Fort Sumter National Historical Park
    set_key US-0933 KFF-0933  # Fort Union National Monument
    set_key US-0934 KFF-0934  # Fossil Butte National Monument
    set_key US-0935 KFF-0935  # George Washington Birthplace National Monument
    set_key US-0936 KFF-0936  # George Washington Carver National Monument
    set_key US-0937 KFF-0937  # Gila Cliff Dwellings National Monument
    set_key US-0938 KFF-0938  # Governors Island National Monument
    set_key US-0939 KFF-0939  # Grand Portage National Monument
    set_key US-0940 KFF-0940  # Hagerman Fossil Beds National Monument
    set_key US-0941 KFF-0941  # Hohokam Pima National Monument
    set_key US-0942 KFF-0942  # Homestead National Historical Park
    set_key US-0943 KFF-0943  # Hovenweep National Monument
    set_key US-0944 KFF-0944  # Jewel Cave National Monument
    set_key US-0945 KFF-0945  # John Day Fossil Beds National Monument
    set_key US-0946 KFF-0946  # Lava Beds National Monument
    set_key US-0947 KFF-0947  # Little Bighorn Battlefield National Monument
    set_key US-0948 KFF-0948  # Montezuma Castle National Monument
    set_key US-0949 KFF-0949  # Muir Woods National Monument
    set_key US-0950 KFF-0950  # Natural Bridges National Monument
    set_key US-0951 KFF-0951  # Navajo National Monument
    set_key US-0952 KFF-0952  # Ocmulgee National Monument
    set_key US-0953 KFF-0953  # Oregon Caves National Monument
    set_key US-0954 KFF-0954  # Organ Pipe Cactus National Monument
    set_key US-0955 KFF-0955  # Petroglyph National Monument
    set_key US-0956 KFF-0956  # Pipe Spring National Monument
    set_key US-0957 KFF-0957  # Pipestone National Monument
    set_key US-0958 KFF-0958  # Poverty Point National Monument
    set_key US-0959 KFF-0959  # Rainbow Bridge National Monument
    set_key US-0960 KFF-0960  # Russell Cave National Monument
    set_key US-0961 KFF-0961  # Salinas Pueblo Missions National Monument
    set_key US-0962 KFF-0962  # Scotts Bluff National Monument
    set_key US-0963 KFF-0963  # Statue of Liberty National Monument
    set_key US-0964 KFF-0964  # Sunset Crater Volcano National Monument
    set_key US-0965 KFF-0965  # Timpanogos Cave National Monument
    set_key US-0966 KFF-0966  # Tonto National Monument
    set_key US-0967 KFF-0967  # Tuzigoot National Monument
    set_key US-0969 KFF-0969  # Walnut Canyon National Monument
    set_key US-0970 KFF-0970  # White Sands National Park
    set_key US-0971 KFF-0971  # World War II Valor in the Pacific National Monument
    set_key US-0972 KFF-0972  # Wupatki National Monument
    set_key US-0973 KFF-0973  # Yucca House National Monument
    set_key US-0974 KFF-0974  # Tule Springs Fossil Beds National Monument
    set_key US-0975 KFF-0975  # Waco Mammoth National Monument
    set_key US-0976 KFF-0976  # Castle Mountains National Monument
    set_key US-0977 KFF-0977  # Stonewall National Monument
    set_key US-0978 KFF-0978  # Apple River Canyon State Park
    set_key US-0979 KFF-0979  # Argyle Lake State Park
    set_key US-0980 KFF-0980  # Beall Woods State Park
    set_key US-0981 KFF-0981  # Beaver Dam State Park
    set_key US-0982 KFF-0982  # Buffalo Rock State Park
    set_key US-0983 KFF-0983  # Campbell's Island State Park
    set_key US-0984 KFF-0984  # Castle Rock State Park
    set_key US-0985 KFF-0985  # Cave-In-Rock State Park
    set_key US-0986 KFF-0986  # Chain-O-Lakes State Park
    set_key US-0987 KFF-0987  # Channahon Parkway State Park
    set_key US-0988 KFF-0988  # Delabar State Park
    set_key US-0989 KFF-0989  # Dixon Springs State Park
    set_key US-0990 KFF-0990  # Donnelley DePue State Park
    set_key US-0991 KFF-0991  # Eldon Hazlet State Park
    set_key US-0992 KFF-0992  # Ferne Clyffe State Park
    set_key US-0993 KFF-0993  # Fort Massac State Park
    set_key US-0994 KFF-0994  # Fox Ridge State Park
    set_key US-0995 KFF-0995  # Gebhard Woods State Park
    set_key US-0996 KFF-0996  # Giant City State Park
    set_key US-0997 KFF-0997  # Hennepin Canal Parkway State Park
    set_key US-0998 KFF-0998  # Horseshoe Lake State Park
    set_key US-0999 KFF-0999  # Illini State Park
    set_key US-1000 KFF-1000  # Illinois Beach State Park
    set_key US-1001 KFF-1001  # James Pate Philip State Park
    set_key US-10019 KFF-4970  # Upper Klamath River Wild and Scenic River
    set_key US-1002 KFF-1002  # Johnson Sauk Trail State Park
    set_key US-10020 KFF-4973  # Rogue River (Upper and Lower) Wild and Scenic River
    set_key US-1003 KFF-1003  # Jubilee College State Park
    set_key US-1004 KFF-1004  # Kankakee River State Park
    set_key US-1005 KFF-1005  # Lake Le-Aqua-Na State Park
    set_key US-1006 KFF-1006  # Lake Murphysboro State Park
    set_key US-10063 KFF-6558  # Crystal Waters State Game Land
    set_key US-1007 KFF-1007  # Lincoln Trail State Park
    set_key US-10070 KFF-6857  # Menan Buttes National Natural Landmark
    set_key US-10075 KFF-5348  # Nepaug State Forest
    set_key US-10078 KFF-4754  # Rockefeller State Park Preserve
    set_key US-10079 KFF-5355  # Pootatuck State Forest
    set_key US-1008 KFF-1008  # Lowden State Park
    set_key US-10080 KFF-6837  # Long Point on Lake Chautauqua State Park
    set_key US-10081 KFF-6966  # Long Point (Thousand Islands) State Park
    set_key US-10086 KFF-5330  # Algonquin State Forest
    set_key US-10089 KFF-5338  # Massacoe State Forest
    set_key US-1009 KFF-1009  # Matthiessen State Park
    set_key US-10090 KFF-6755  # Mackinaw River State Fish and Wildlife Area
    set_key US-10091 KFF-6756  # Powerton Lake State Fish and Wildlife Area
    set_key US-10092 KFF-6823  # Seaside
    set_key US-10093 KFF-6757  # Rock Island Trail State Park
    set_key US-10094 KFF-6759  # Spring Lake State Fish and Wildlife Area
    set_key US-10095 KFF-5650  # Woodford State Fish and Wildlife Area
    set_key US-10098 KFF-6607  # Green River National Wildlife Refuge
    set_key US-1010 KFF-1010  # Mississippi Palisades State Park
    set_key US-10100 KFF-6576  # Anderson Lake
    set_key US-1011 KFF-1011  # Montebello State Park
    set_key US-10110 KFF-6695  # Wire Road State Conservation Area
    set_key US-10116 KFF-6660  # Kings Prairie Access State Conservation Area
    set_key US-10117 KFF-7269  # Boone Forestlands Wildlife Management Area
    set_key US-1012 KFF-1012  # Moraine Hills State Park
    set_key US-10121 KFF-7270  # Cane Creek Wildlife Management Area
    set_key US-10128 KFF-7366  # Ferguson Creek Wildlife Management Area
    set_key US-1013 KFF-1013  # Morrison-Rockwood State Park
    set_key US-10131 KFF-7367  # Gabbard Branch Wildlife Management Area
    set_key US-10134 KFF-7275  # White Lake Wetlands State Conservation Area
    set_key US-10137 KFF-7368  # Harris-Dickerson Wildlife Management Area
    set_key US-10138 KFF-7369  # Hoskins Wildlife Management Area
    set_key US-1014 KFF-1014  # Nauvoo State Park
    set_key US-10141 KFF-7370  # Kentucky Ridge Wildlife Management Area
    set_key US-10142 KFF-6572  # Rockefeller Wildlife Refuge
    set_key US-1015 KFF-1015  # Pere Marquette State Park
    set_key US-10150 NIL-0000  # Ohio River Islands (WV); WWFF candidates: KFF-6608, KFF-6609, KFF-6610
    set_key US-1016 KFF-1016  # Edward R. Madigan State Park
    set_key US-10165 KFF-6655  # Grand Bluffs State Conservation Area
    set_key US-1017 KFF-1017  # Ramsey Lake State Park
    set_key US-10175 KFF-6832  # Milltown State Park
    set_key US-10176 KFF-6831  # Granite Ghost Town
    set_key US-1018 KFF-1018  # Red Hills State Park
    set_key US-1019 KFF-1019  # Rock Cut State Park
    set_key US-1020 KFF-1020  # Sam Parr State Park
    set_key US-10203 KFF-6967  # Quartz Mountain State Park
    set_key US-10207 KFF-6683  # Smoky Waters State Conservation Area
    set_key US-10208 KFF-6657  # Hart Creek State Conservation Area
    set_key US-10209 KFF-6652  # Franklin Island State Conservation Area
    set_key US-1021 KFF-1021  # Sangchris Lake State Park
    set_key US-10210 KFF-6654  # Gist Ranch State Conservation Area
    set_key US-10211 KFF-6686  # Sunklands State Conservation Area
    set_key US-10212 KFF-6666  # Mon-Shon State Conservation Area
    set_key US-10213 KFF-6641  # Capps Creek State Conservation Area
    set_key US-10214 KFF-6669  # Niangua State Conservation Area
    set_key US-10215 KFF-6642  # Cedar Gap State Conservation Area
    set_key US-10216 KFF-6676  # Robert E. Talbot State Conservation Area
    set_key US-10217 KFF-6632  # Ben Cash State Conservation Area
    set_key US-10218 KFF-6687  # The Lewis Family, Dean, Anna Mae and David D. Lewis State Conservation Area
    set_key US-1022 KFF-1022  # Bob Bangert (Quincy District) State Park
    set_key US-1023 KFF-1023  # Siloam Springs State Park
    set_key US-10236 KFF-6815  # Lake Sylvia
    set_key US-1024 KFF-1024  # Silver Springs State Park
    set_key US-10242 KFF-4972  # Table Rocks Management Area
    set_key US-10247 NIL-0000  # Lawrence Creek State Nature Preserve
    set_key US-10249 KFF-6945  # Salmon River National Wild and Scenic River
    set_key US-1025 KFF-1025  # South Shore Park
    set_key US-10251 KFF-6946  # White River National Wild and Scenic River
    set_key US-10257 KFF-5121  # St. Francis Sunken Lands State Wildlife Management Area
    set_key US-1026 KFF-1026  # Spitler Woods State Park
    set_key US-10260 KFF-6612  # Birkhead Mountains Wilderness Area
    set_key US-10262 KFF-6617  # Linville Gorge Wilderness Area
    set_key US-10264 KFF-6678  # Saline Valley State Conservation Area
    set_key US-10265 KFF-6690  # Victoria Glades State Conservation Area
    set_key US-10266 KFF-6689  # Valley View Glades State Conservation Area
    set_key US-10269 KFF-6696  # Young State Conservation Area
    set_key US-1027 KFF-1027  # Starved Rock State Park
    set_key US-10270 KFF-6668  # Myron and Sonya Glassberg Family State Conservation Area
    set_key US-1028 KFF-1028  # Walnut Point State Park
    set_key US-1029 KFF-1029  # Wayne Fitzgerrell State Park
    set_key US-10295 KFF-6973  # Independence River Wild State Forest
    set_key US-10296 KFF-6616  # Joyce Kilmer-Slickrock Wilderness Area
    set_key US-1030 KFF-1030  # Weldon Springs State Park
    set_key US-10308 KFF-6954  # Carlos Avery WMA
    set_key US-10309 KFF-6672  # Plowboy Bend State Conservation Area
    set_key US-1031 KFF-1031  # White Pines Forest State Park
    set_key US-10310 KFF-6677  # Roger V. and Viola Wachal Smith State Conservation Area
    set_key US-10312 KFF-6651  # Earthquake Hollow State Conservation Area
    set_key US-1032 KFF-1032  # William G. Stratton State Park
    set_key US-1033 KFF-1033  # Wolf Creek State Park
    set_key US-1034 KFF-1034  # Blue Springs State Park
    set_key US-10345 KFF-6625  # Carson Lake and Pasture Wildlife Management Area
    set_key US-1035 KFF-1035  # Buck's Pocket State Park
    set_key US-10352 KFF-7278  # Floy Ward McElroy Wildlife Management Area
    set_key US-10353 KFF-7279  # Isle Dernieres Barrier Islands Wildlife Refuge
    set_key US-1036 KFF-1036  # Cathedral Caverns State Park
    set_key US-1037 KFF-1037  # Cheaha Resort State Park
    set_key US-1038 KFF-1038  # Chewacla State Park
    set_key US-10380 KFF-6928  # Orwell WMA Wildlife Management Area
    set_key US-1039 KFF-1039  # De Soto State Park
    set_key US-10391 KFF-6754  # Kishwaukee River State Fish and Wildlife Area
    set_key US-10392 KFF-6637  # Boston Ferry State Conservation Area
    set_key US-10396 KFF-7240  # Black Warrior Wildlife Management Area
    set_key US-10397 KFF-6621  # Southern Nantahala Wilderness Area
    set_key US-1040 KFF-1040  # Florala State Park
    set_key US-10401 KFF-6605  # Merced National Wildlife Area
    set_key US-10407 KFF-6852  # Columbia Plateau State Park
    set_key US-1041 KFF-1041  # Frank Jackson State Park
    set_key US-10410 KFF-6854  # Nisqually State Park
    set_key US-10413 KFF-7280  # Acadiana Conservation Corridor
    set_key US-10414 KFF-5612  # Wateree Heritage Preserve Wildlife Management Area
    set_key US-1042 KFF-1042  # Gulf State Park
    set_key US-10425 KFF-7350  # Goat's Beard Bluff State Natural Area
    set_key US-1043 KFF-1043  # Joe Wheeler State Park
    set_key US-10430 KFF-6938  # St Joe River National Wild and Scenic River
    set_key US-1044 KFF-1044  # Lake Guntersville State Park
    set_key US-1045 KFF-1045  # Lake Lurleen State Park
    set_key US-10458 KFF-6680  # Scrivner Road State Conservation Area
    set_key US-1046 KFF-1046  # Lakepoint Resort State Park
    set_key US-10462 KFF-5231  # DuPuis Wildlife and Enviromental Area
    set_key US-10463 KFF-5693  # Price's Scrub State Park
    set_key US-10466 KFF-6624  # Blue Wing Mountains Herd Management Area
    set_key US-10469 KFF-6626  # McGee Mountain Herd Management Area
    set_key US-1047 KFF-1047  # Meaher State Park
    set_key US-1048 KFF-1048  # Monte Sano State Park
    set_key US-1049 KFF-1049  # Oak Mountain State Park
    set_key US-1050 KFF-1050  # Rickwood Caverns State Park
    set_key US-10509 KFF-5640  # Sam Houston National Forest State Wildlife Management Area
    set_key US-1051 KFF-1051  # Wind Creek State Park
    set_key US-10510 KFF-7259  # Dos Cabezas Mountains State Wildlife Area
    set_key US-10512 KFF-7257  # Verde River Greenway State Natural Area
    set_key US-10513 KFF-6816  # Granite Mountain Hotshots
    set_key US-10514 KFF-4955  # San Pedro Riparian National Conservation Area
    set_key US-1052 KFF-1052  # Alamo Lake State Park
    set_key US-10521 KFF-2575  # Garnet Ghost Town
    set_key US-1053 KFF-1053  # Boyce Thompson Arboretum State Park
    set_key US-10530 KFF-6826  # Coeur d'Alene Parkway
    set_key US-10533 NIL-0000  # Watson Lake State Wildlife Area
    set_key US-10534 NIL-0000  # Garfield Creek State Wildlife Area
    set_key US-10535 NIL-0000  # West Rifle Creek State Wildlife Area
    set_key US-10539 NIL-0000  # Rifle Falls State Fish Hatchery
    set_key US-1054 KFF-1054  # Buckskin Mountain State Park
    set_key US-10540 NIL-0000  # Bellevue-Watson State Fish Hatchery
    set_key US-1055 KFF-1055  # Catalina State Park
    set_key US-10550 KFF-7466  # Scanlon State Conservation Area
    set_key US-10554 KFF-7467  # Suwannee Street State Conservation Area
    set_key US-10555 KFF-6671  # Pleasant Hope State Conservation Area
    set_key US-10556 KFF-6664  # Little Sac Woods State Conservation Area
    set_key US-10557 KFF-6646  # Dale Sare State Conservation Area
    set_key US-10559 KFF-6702  # Camp Branch State Conservation Area
    set_key US-1056 KFF-1056  # Cattail Cove State Park
    set_key US-10566 KFF-6733  # Stuart's Landing South State Conservation Area
    set_key US-10567 KFF-6717  # Hatchbend State Conservation Area
    set_key US-1057 KFF-1057  # Dead Horse Ranch State Park
    set_key US-10572 KFF-6629  # Amidon Memorial State Conservation Area
    set_key US-10573 KFF-6645  # Coldwater State Conservation Area
    set_key US-10575 KFF-6692  # Walnut Woods State Conservation Area
    set_key US-10579 KFF-6650  # Dr. Frederick Marshall State Conservation Area
    set_key US-1058 KFF-1058  # Homolovi State Park
    set_key US-10580 KFF-6691  # Wagner State Conservation Area
    set_key US-10581 KFF-6662  # La Due Bottoms State Conservation Area
    set_key US-10582 KFF-6659  # Kearn Memorial State Conservation Area
    set_key US-10583 KFF-6640  # Bryson's Hope State Conservation Area
    set_key US-10584 KFF-6653  # Gama Grass Prairie State Conservation Area
    set_key US-10586 KFF-6697  # Youngdahl Urban State Conservation Area
    set_key US-10587 KFF-6635  # Blue Lick State Conservation Area
    set_key US-10588 KFF-7468  # Branford-Bend State Conservation Area
    set_key US-1059 KFF-1059  # Kartchner Caverns State Park
    set_key US-10590 KFF-7469  # Lake Alto State State Conservation Area
    set_key US-10591 KFF-7470  # Steinhatchee Rise State Conservation Area
    set_key US-10595 KFF-6661  # Knob Lick State Conservation Area
    set_key US-10596 KFF-6684  # Spring Creek Gap State Conservation Area
    set_key US-1060 KFF-1060  # Lake Havasu State Park
    set_key US-10600 KFF-6667  # Mule Shoe State Conservation Area
    set_key US-10604 KFF-7471  # Blue Sink State Conservation Area
    set_key US-10609 KFF-6839  # Bolon Island Tideways State Park
    set_key US-1061 KFF-1061  # Lost Dutchman State Park
    set_key US-10614 KFF-7472  # Roline State Conservation Area
    set_key US-10618 KFF-7473  # Wolf Creek State Conservation Area
    set_key US-10619 KFF-7474  # Little River Wildlife Management Area
    set_key US-1062 KFF-1062  # Lyman Lake State Park
    set_key US-10620 KFF-7475  # Jerry Branch State Conservation Area
    set_key US-1063 KFF-1063  # Oracle State Park
    set_key US-1064 KFF-1064  # Patagonia Lake State Park
    set_key US-1065 KFF-1065  # Picacho Peak State Park
    set_key US-1066 KFF-1066  # Red Rock State Park
    set_key US-10666 KFF-6752  # Double T State Fish and Wildlife Area
    set_key US-1067 KFF-1067  # Roper Lake State Park
    set_key US-1068 KFF-1068  # Slide Rock State Park
    set_key US-1069 KFF-1069  # Tonto Natural Bridge State Park
    set_key US-1070 KFF-1070  # Arkansas Museam of Natural Resources State Park
    set_key US-10705 KFF-5771  # Charlie Heath Memorial Conservation Area
    set_key US-1072 KFF-1072  # Bull Shoals White River State Park
    set_key US-1073 KFF-1073  # Cane Creek State Park
    set_key US-1074 KFF-1074  # Conway Cemetery State Park
    set_key US-1075 KFF-1075  # Cossatot River State Park
    set_key US-1076 KFF-1076  # Crater of Diamonds State Park
    set_key US-1077 KFF-1077  # Crowley's Ridge State Park
    set_key US-10777 KFF-6753  # Fort Defiance State Park
    set_key US-1078 KFF-1078  # Daisy State Park
    set_key US-10780 KFF-6977  # Laramie Peak Wildlife Habitat Management Area
    set_key US-10784 KFF-5536  # Deep Creek Lake Natural Resource Management Area
    set_key US-1079 KFF-1079  # Davidsonville Historic (Old) State Park
    set_key US-10793 KFF-7151  # Jelm Wildlife Habitat Management Area
    set_key US-10797 KFF-7049  # Half Moon Wildlife Habitat Management Area
    set_key US-1080 KFF-1080  # DeGray Lake Resort State Park
    set_key US-10806 KFF-7037  # Sunshine Wildlife Habitat Management Area
    set_key US-10808 KFF-7041  # Soda Lake Wildlife Habitat Management Area
    set_key US-1081 KFF-1081  # Delta Heritage Trails State Park
    set_key US-1082 KFF-1082  # Devil's Den State Park
    set_key US-10828 NIL-0000  # Quebec 01 Missile Alert Facility State Park
    set_key US-1083 KFF-1083  # Hampson Museum State Park
    set_key US-1084 KFF-1084  # Herman Davis State Park
    set_key US-1085 KFF-1085  # Hobbs State Park
    set_key US-10852 KFF-6758  # Rockton Bog State Nature Preserve
    set_key US-1086 KFF-1086  # Jacksonport State Park
    set_key US-1087 KFF-1087  # Jenkins Ferry State Park
    set_key US-10875 KFF-7005  # Kern National Wild and Scenic River
    set_key US-1088 KFF-1088  # Lake Catherine State Park
    set_key US-1089 KFF-1089  # Lake Charles State Park
    set_key US-1090 KFF-1090  # Lake Chicot State Park
    set_key US-1091 KFF-1091  # Lake Dardanelle State Park
    set_key US-1092 KFF-1092  # Lake Fort Smith State Park
    set_key US-1093 KFF-1093  # Lake Frierson State Park
    set_key US-1094 KFF-1094  # Lake Ouachita State Park
    set_key US-1095 KFF-1095  # Lake Poinsett State Park
    set_key US-10952 KFF-5353  # Paugussett State Forest
    set_key US-1096 KFF-1096  # Logoly State Park
    set_key US-10961 KFF-5339  # Mattatuck State Forest
    set_key US-1097 KFF-1097  # Louisiana Purchase State Park
    set_key US-1098 KFF-1098  # Lower White River Museam State Park
    set_key US-1099 KFF-1099  # Mammoth Spring State Park
    set_key US-1100 KFF-1100  # Marks' Mills State Park
    set_key US-1101 KFF-1101  # Millwood State Park
    set_key US-1102 KFF-1102  # Mississippi River State Park
    set_key US-11024 KFF-6926  # Blanket Flower Prairie SNA State Conservation Area
    set_key US-11028 KFF-7253  # Robbins Butte State Wildlife Area
    set_key US-1103 KFF-1103  # Moro Bay State Park
    set_key US-1104 KFF-1104  # Mount Magazine State Park
    set_key US-1105 KFF-1105  # Mount Nebo State Park
    set_key US-11050 KFF-6834  # Ice Age Fossils State Park
    set_key US-1106 KFF-1106  # Historic Washington State Park
    set_key US-11065 KFF-6760  # Rose Pond State Conservation Area
    set_key US-1107 KFF-1107  # Ozark Folk Center State Park
    set_key US-1108 KFF-1108  # Parkin Archeological State Park
    set_key US-11087 KFF-7254  # Upper Verde River State Wildlife Area
    set_key US-11088 KFF-7347  # Frierson Wildlife Management Area
    set_key US-1109 KFF-1109  # Petit Jean State Park
    set_key US-1110 KFF-1110  # Pinnacle Mountain State Park
    set_key US-1111 KFF-1111  # Poison Springs Battleground State Park
    set_key US-1112 KFF-1112  # Powhatan State Park
    set_key US-11124 KFF-6817  # Rockin' River Ranch
    set_key US-1113 KFF-1113  # Prairie Grove Battlefield State Park
    set_key US-1114 KFF-1114  # Queen Wilhelmina State Park
    set_key US-11146 KFF-6833  # Somers Beach State Park
    set_key US-11148 KFF-6957  # Hardwood Creek WMA
    set_key US-1115 KFF-1115  # South Arkansas Arboretum State Park
    set_key US-1116 KFF-1116  # Toltec Mounds Archeological State Park
    set_key US-1117 KFF-1117  # Village Creek State Park
    set_key US-1118 KFF-1118  # White Oak Lake State Park
    set_key US-1119 KFF-1119  # Withrow Springs State Park
    set_key US-1120 KFF-1120  # Woolly Hollow State Park
    set_key US-1121 KFF-1121  # Ahjumawi Lava Springs State Park
    set_key US-1122 KFF-1122  # Andrew Molera State Park
    set_key US-11223 KFF-4539  # Ruth B. Kirby Gilchrist Blue Springs State Park
    set_key US-1123 KFF-1123  # Angel Island State Park
    set_key US-11231 KFF-6827  # Sideling Hill Creek
    set_key US-1124 KFF-1124  # Trione-Annadel State Park
    set_key US-11241 KFF-7432  # Oak Ridge Wildlife Management Area
    set_key US-11247 KFF-6248  # PA 332 State Game Land
    set_key US-1125 KFF-1125  # Ano Nuevo State Park
    set_key US-1126 KFF-1126  # Anza Borrego Desert State Park
    set_key US-11268 KFF-4570  # Neches River National Wildlife Refuge
    set_key US-1127 KFF-1127  # Arthur B. Ripley Desert Woodland State Park
    set_key US-1128 KFF-1128  # Bidwell-Sacramento River State Park
    set_key US-1129 KFF-1129  # Big Basin Redwoods State Park
    set_key US-1130 KFF-1130  # Border Field State Park
    set_key US-11307 KFF-6909  # Princeton Wildlife Area
    set_key US-1131 KFF-1131  # Bothe-Napa Valley State Park
    set_key US-1132 KFF-1132  # Burton Creek State Park
    set_key US-11323 KFF-6910  # Syracuse Wildlife Area
    set_key US-1133 KFF-1133  # Butano State Park
    set_key US-11337 KFF-5887  # Hamburg Mountain Wildlife Management Area
    set_key US-11338 KFF-6764  # Stow Creek State Park
    set_key US-1134 KFF-1134  # Calaveras Big Trees State Park
    set_key US-11340 KFF-5888  # Higbee Beach Wildlife Management Area
    set_key US-1135 KFF-1135  # Castle Crags State Park
    set_key US-11353 KFF-7354  # Kirk Dupps Beaver Lake Wildlife Management Area
    set_key US-11358 KFF-6912  # Canaan State Conservation Area
    set_key US-11359 KFF-6914  # Long Ridge State Conservation Area
    set_key US-1136 KFF-1136  # Castle Rock State Park
    set_key US-11360 KFF-6915  # Mora State Conservation Area
    set_key US-11361 KFF-6913  # Hi Lonesome Prairie State Conservation Area
    set_key US-11363 KFF-5780  # Mineral Hills State Conservation Area
    set_key US-1137 KFF-1137  # Caswell Memorial State Park
    set_key US-11370 KFF-6916  # Shannon Ranch State Conservation Area
    set_key US-11371 KFF-6911  # Bee Hollow State Conservation Area
    set_key US-1138 KFF-1138  # China Camp State Park
    set_key US-1139 KFF-1139  # Chino Hills State Park
    set_key US-11394 KFF-7358  # Muddy Creek Wildlife Management Area
    set_key US-1140 KFF-1140  # Clear Lake State Park
    set_key US-11400 KFF-6900  # Chalet Wildlife Management Area
    set_key US-1141 KFF-1141  # Crystal Cove State Park
    set_key US-1142 KFF-1142  # Cuyamaca Rancho State Park
    set_key US-1143 KFF-1143  # Del Norte Coast Redwoods State Park
    set_key US-1144 KFF-1144  # D L Bliss State Park
    set_key US-1145 KFF-1145  # Donner Memorial State Park
    set_key US-1146 KFF-1146  # Ed Z'berg Sugar Pine Point State Park
    set_key US-1147 KFF-1147  # Emerald Bay State Park
    set_key US-1148 KFF-1148  # Estero Bluffs State Park
    set_key US-1149 KFF-1149  # The Forest of Nisene Marks State Park
    set_key US-1150 KFF-1150  # Fort Ord Dunes State Park
    set_key US-1151 KFF-1151  # Fremont Peak State Park
    set_key US-1152 KFF-1152  # Garrapata State Park
    set_key US-1153 KFF-1153  # Gaviota State Park
    set_key US-1154 KFF-1154  # Great Valley Grasslands State Park
    set_key US-1155 KFF-1155  # Grizzly Creek Redwoods State Park
    set_key US-1156 KFF-1156  # Grover Hot Springs State Park
    set_key US-1157 KFF-1157  # Harmony Headlands State Park
    set_key US-1158 KFF-1158  # Hearst San Simeon State Park
    set_key US-1159 KFF-1159  # Hendy Woods State Park
    set_key US-1160 KFF-1160  # Henry Cowell Redwoods State Park
    set_key US-1161 KFF-1161  # Henry W. Coe State Park
    set_key US-1162 KFF-1162  # Humboldt Lagoons State Park
    set_key US-11621 KFF-6901  # Copicut Wildlife Management Area
    set_key US-11625 KFF-6902  # Erwin S. Wilder Wildlife Management Area
    set_key US-1163 KFF-1163  # Humboldt Redwoods State Park
    set_key US-11633 KFF-6903  # Hockomock Swamp Wildlife Management Area
    set_key US-1164 KFF-1164  # Jedediah Smith Redwoods State Park
    set_key US-1165 KFF-1165  # Julia Pfeiffer Burns State Park
    set_key US-1166 KFF-1166  # Leo Carrillo State Park
    set_key US-1167 KFF-1167  # Limekiln State Park
    set_key US-11673 KFF-6896  # Great Council State Park
    set_key US-11678 KFF-6904  # Mill Brook Bogs Wildlife Management Area
    set_key US-1168 KFF-1168  # MacKerricher State Park
    set_key US-1169 KFF-1169  # Malibu Creek State Park
    set_key US-11695 KFF-6905  # Taunton River Wildlife Management Area
    set_key US-11697 KFF-6906  # West Meadows Wildlife Management Area
    set_key US-1170 KFF-1170  # Manchester State Park
    set_key US-1171 KFF-1171  # McArthur-Burney Falls Memorial State Park
    set_key US-11713 KFF-6972  # Dale Bumpers White River National Wildlife Refuge
    set_key US-1172 KFF-1172  # Mendocino Headlands State Park
    set_key US-1173 KFF-1173  # Mendocino Woodlands State Park
    set_key US-1174 KFF-1174  # Montana de Oro State Park
    set_key US-1175 KFF-1175  # Morro Bay State Park
    set_key US-1176 KFF-1176  # Mount Diablo State Park
    set_key US-1177 KFF-1177  # Mount San Jacinto State Park
    set_key US-1178 KFF-1178  # Mount Tamalpais State Park
    set_key US-1179 KFF-1179  # Navarro River Redwoods State Park
    set_key US-1180 KFF-1180  # Pacheco State Park
    set_key US-1181 KFF-1181  # Palomar Mountain State Park
    set_key US-1182 KFF-1182  # Sue-Meg State Park
    set_key US-11824 KFF-6931  # PA 336 State Game Land
    set_key US-1183 KFF-1183  # Pfeiffer Big Sur State Park
    set_key US-1184 KFF-1184  # Placerita Canyon State Park
    set_key US-11849 KFF-7388  # Wantastiquet Mountain State Natural Area
    set_key US-1185 KFF-1185  # Plumas Eureka State Park
    set_key US-11855 KFF-4952  # Steese National Conservation Area
    set_key US-11858 KFF-6969  # Middle Fork Bottoms State Park
    set_key US-1186 KFF-1186  # Point Mugu State Park
    set_key US-1187 KFF-1187  # Portola Redwoods State Park
    set_key US-11875 KFF-6895  # Blackburn State Park
    set_key US-11879 KFF-6898  # North Chickamauga Creek Gorge State Park
    set_key US-1188 KFF-1188  # Prairie Creek Redwoods State Park
    set_key US-11889 KFF-7195  # Piceance State Wildlife Area
    set_key US-1189 KFF-1189  # Red Rock Canyon State Park
    set_key US-11891 NIL-0000  # Tilman Bishop State Wildlife Area
    set_key US-11892 KFF-7206  # Jerry Creek Reservoirs State Wildlife Area
    set_key US-11897 NIL-0000  # Beaver Creek BLM Wilderness Area
    set_key US-11899 NIL-0000  # South Republican State Wildlife Area
    set_key US-1190 KFF-1190  # Richardson Grove State Park
    set_key US-11902 KFF-6091  # Camp Hale-Continental Divide
    set_key US-1191 KFF-1191  # Robert Louis Stevenson State Park
    set_key US-11915 NIL-0000  # Hubbard Mesa OHV BLM Special Recreation Management Area
    set_key US-11918 KFF-7456  # Sherwood Forest State Natural Area
    set_key US-1192 KFF-1192  # Russian Gulch State Park
    set_key US-11920 NIL-0000  # Mount Evans State Wildlife Area
    set_key US-11923 NIL-0000  # Sharptail Ridge State Wildlife Area
    set_key US-11924 NIL-0000  # Douglas Reservoir State Wildlife Area
    set_key US-11926 NIL-0000  # Lon Hagler State Wildlife Area
    set_key US-1193 KFF-1193  # Saddleback Butte State Park
    set_key US-11938 NIL-0000  # Parvin Lake State Wildlife Area
    set_key US-11939 NIL-0000  # Poudre River State Wildlife Area
    set_key US-1194 KFF-1194  # Salt Point State Park
    set_key US-11940 NIL-0000  # Simpsons Pond State Wildlife Area
    set_key US-11941 NIL-0000  # Smith Lake State Wildlife Area
    set_key US-11943 KFF-7260  # Sonoita Creek State Natural Area
    set_key US-11944 KFF-6894  # Dankworth Pond State Park
    set_key US-11949 KFF-7363  # Becker Lake State Wildlife Area
    set_key US-1195 KFF-1195  # Samuel P. Taylor State Park
    set_key US-11950 KFF-7251  # Cluff Ranch State Wildlife Area
    set_key US-1196 KFF-1196  # San Bruno Mountain State Park
    set_key US-11962 KFF-6927  # Manston Marsh Wildlife Management Area
    set_key US-11964 KFF-5894  # Peaslee Wildlife Management Area
    set_key US-11965 KFF-5883  # Glassboro Wildlife Management Area
    set_key US-1197 KFF-1197  # Sinkyone Wilderness State Park
    set_key US-11972 KFF-6955  # Dead Lake Wildlife Management Area
    set_key US-11973 KFF-6929  # Rothsay Wildlife Management Area
    set_key US-11978 KFF-7256  # Whitewater Draw State Wildlife Area
    set_key US-1198 KFF-1198  # Sonoma Coast State Park
    set_key US-11980 KFF-6951  # Bethel Wildlife Management Area
    set_key US-11983 KFF-6959  # Keystone Wildlife Management Area
    set_key US-11984 KFF-7362  # Quigley-Achee State Wildlife Area
    set_key US-11985 KFF-7252  # Raymond State Wildlife Area
    set_key US-11987 KFF-7255  # White Mountain Grasslands State Wildlife Area
    set_key US-11988 KFF-6918  # Cohansey River Wildlife Management Area
    set_key US-11989 KFF-5884  # Great Bay Boulevard Wildlife Management Area
    set_key US-1199 KFF-1199  # South Yuba River State Park
    set_key US-11991 KFF-5898  # South Branch Wildlife Management Area
    set_key US-11992 KFF-5901  # Whiting Wildlife Management Area
    set_key US-1200 KFF-1200  # Sugarloaf Ridge State Park
    set_key US-1201 KFF-1201  # Sutter Buttes State Park
    set_key US-1202 KFF-1202  # Tolowa Dunes State Park
    set_key US-12028 KFF-7313  # Barren Fork Wildlife Management Area
    set_key US-1203 KFF-1203  # Tomales Bay State Park
    set_key US-1204 KFF-1204  # Topanga State Park
    set_key US-1205 KFF-1205  # Van Damme State Park
    set_key US-12058 KFF-6935  # Gordie Mikkelson WMA
    set_key US-1206 KFF-1206  # Washoe Meadows State Park
    set_key US-12061 KFF-5371  # Hickok Brook Multiple Use Area
    set_key US-1207 KFF-1207  # Wilder Ranch State Park
    set_key US-12073 KFF-6956  # Elmo Wildlife Management Area
    set_key US-12075 KFF-6962  # Staples Wildlife Management Area
    set_key US-1208 KFF-1208  # Arkansas River Headwaters State Park
    set_key US-1209 KFF-1209  # Barr Lake State Park
    set_key US-12097 KFF-6718  # Hickory Hammock Wildlife Management Area
    set_key US-12099 KFF-6917  # Alexauken Creek Wildlife Management Area
    set_key US-1210 KFF-1210  # Boyd Lake State Park
    set_key US-12101 KFF-5879  # Clinton Wildlife Management Area
    set_key US-12102 KFF-6919  # Ken Lockwood Gorge Wildlife Management Area
    set_key US-12103 KFF-6920  # Lockatong Wildlife Management Area
    set_key US-12105 KFF-5897  # Rockport Wildlife Management Area
    set_key US-12106 NIL-0000  # Brainard Lake Recreation Area National Forest
    set_key US-1211 KFF-1211  # Castlewood Canyon State Park
    set_key US-1212 KFF-1212  # Chatfield State Park
    set_key US-12125 KFF-7476  # Kissimmee River - Yates Marsh Public Use Area
    set_key US-12129 KFF-6923  # Shingle Creek State Conservation Area
    set_key US-1213 KFF-1213  # Cherry Creek State Park
    set_key US-12131 KFF-7477  # Loxahatchee River - Cypress Creek Creek Management Area
    set_key US-12132 KFF-7478  # Kissimmee River - Chandler Slough Public Use Area
    set_key US-12133 KFF-7479  # Kissimmee Chain of Lakes - Catfish Creek Wildlife Management Area
    set_key US-12135 KFF-7480  # Myakka River - Flatford Swamp State Conservation area
    set_key US-12136 KFF-6708  # Deep Creek Preserve
    set_key US-12138 NIL-0000  # Charlie Meyers State Wildlife Area
    set_key US-12139 NIL-0000  # Cline Ranch State Wildlife Area
    set_key US-1214 KFF-1214  # Cheyenne Mountain State Park
    set_key US-12140 NIL-0000  # Spinney Mountain State Wildlife Area
    set_key US-1215 KFF-1215  # Crawford State Park
    set_key US-12152 KFF-6953  # Canosia Wildlife Management Area
    set_key US-1216 KFF-1216  # Eldorado Canyon State Park
    set_key US-12167 KFF-5566  # Fort Cobb Wildlife Management Area
    set_key US-12169 KFF-4964  # El Malpais National Conservation Area
    set_key US-1217 KFF-1217  # Eleven Mile State Park
    set_key US-12170 NIL-0000  # Teter-Michigan Creek State Wildlife Area
    set_key US-12171 NIL-0000  # Tomahawk State Wildlife Area
    set_key US-12172 NIL-0000  # James Mark Jones State Wildlife Area
    set_key US-12176 NIL-0000  # Frank State Wildlife Area
    set_key US-12178 NIL-0000  # Atwood State Wildlife Area
    set_key US-1218 KFF-1218  # Elkhead State Park
    set_key US-12181 KFF-7171  # Banner Lakes State Wildlife Area
    set_key US-12186 NIL-0000  # Bob Terrell State Wildlife Area
    set_key US-12187 NIL-0000  # Roaring Fork State Wildlife Area
    set_key US-12188 NIL-0000  # Brush Prairie Ponds State Wildlife Area
    set_key US-1219 KFF-1219  # Golden Gate Canyon State Park
    set_key US-1220 KFF-1220  # Harvey Gap State Park
    set_key US-12204 KFF-7372  # Calling Panther Lake Wildlife Management Area
    set_key US-1221 KFF-1221  # Highline Lake State Park
    set_key US-12216 KFF-6698  # Santa Rosa Plateau Ecological Preserve
    set_key US-1222 KFF-1222  # Jackson Lake State Park
    set_key US-1223 KFF-1223  # James M. Robb - Colorado River State Park
    set_key US-12234 KFF-7323  # Allegheny River National Recreational River
    set_key US-12235 KFF-6948  # Clarion National Wild and Scenic River
    set_key US-1224 KFF-1224  # John Martin Reservoir State Park
    set_key US-1225 KFF-1225  # Lake Pueblo State Park
    set_key US-1226 KFF-1226  # Lathrop State Park
    set_key US-1228 KFF-1228  # Lory State Park
    set_key US-1229 KFF-1229  # Mancos State Park
    set_key US-1230 KFF-1230  # Mueller State Park
    set_key US-1231 KFF-1231  # Navajo State Park
    set_key US-1232 KFF-1232  # North Sterling State Park
    set_key US-12320 KFF-5649  # Yadkin River State Trail
    set_key US-12321 NIL-0000  # Red Hill BLM Special Recreation Management Area
    set_key US-1233 KFF-1233  # Paonia State Park
    set_key US-1234 KFF-1234  # Pearl Lake State Park
    set_key US-12343 KFF-6949  # White Salmon National Wild and Scenic River
    set_key US-12347 KFF-6944  # Grande Ronde National Wild and Scenic River
    set_key US-1235 KFF-1235  # Ridgway State Park
    set_key US-12354 NIL-0000  # Red Lion State Wildlife Area
    set_key US-12355 NIL-0000  # Jumbo Reservoir State Wildlife Area
    set_key US-1236 KFF-1236  # Rifle Falls State Park
    set_key US-12360 KFF-7188  # Wolf River State Forest
    set_key US-12361 KFF-6970  # Scott's Gulf Wilderness State Park
    set_key US-1237 KFF-1237  # Rifle Gap State Park
    set_key US-12372 KFF-6964  # Cave Rock State Park
    set_key US-12373 KFF-6965  # Sand Harbor State Park
    set_key US-12378 KFF-6963  # Whitewater Wildlife Management Area
    set_key US-1238 KFF-1238  # Roxborough State Park
    set_key US-12380 KFF-6961  # McCarthy Lake Wildlife Management Area
    set_key US-1239 KFF-1239  # San Luis State Wildlife Area
    set_key US-1240 KFF-1240  # Spinney Mountain State Park
    set_key US-1241 KFF-1241  # St. Vrain State Park
    set_key US-1242 KFF-1242  # Stagecoach State Park
    set_key US-1243 KFF-1243  # State Forest State Park
    set_key US-1244 KFF-1244  # Staunton State Park
    set_key US-12447 KFF-6934  # Rice Creek WMA
    set_key US-1245 KFF-1245  # Steamboat Lake State Park
    set_key US-12452 KFF-6936  # Bradshaw Lake WMA
    set_key US-12455 NIL-0000  # Mt. Shavano State Fish Hatchery
    set_key US-12456 NIL-0000  # Stalker Lake State Wildlife Area
    set_key US-12457 KFF-6932  # Riverlands State Forest
    set_key US-12458 KFF-6933  # Mille Lacs WMA
    set_key US-1246 KFF-1246  # Sweitzer Lake State Park
    set_key US-1247 KFF-1247  # Sylvan Lake State Park
    set_key US-1248 KFF-1248  # Trinidad Lake State Park
    set_key US-12489 KFF-7281  # Bogue Chitto Wildlife Management Area
    set_key US-1249 KFF-1249  # Vega State Park
    set_key US-1250 KFF-1250  # Yampa River State Park
    set_key US-1251 KFF-1251  # Carr Creek State Park
    set_key US-1252 KFF-1252  # Columbus Belmont State Park
    set_key US-1253 KFF-1253  # Dawkins Line Rail Trail State Park
    set_key US-1254 KFF-1254  # E.P. 'Tom' Sawyer State Park
    set_key US-1255 KFF-1255  # Fishtrap Lake State Park
    set_key US-1256 KFF-1256  # Fort Boonesborough State Park
    set_key US-1257 KFF-1257  # General Burnside State Park
    set_key US-12575 KFF-6987  # Steptoe Valley Wildlife Management Area
    set_key US-1258 KFF-1258  # Grayson Lake State Park
    set_key US-12585 KFF-7201  # Elliot State Wildlife Area
    set_key US-12586 NIL-0000  # Jean K Tool State Wildlife Area
    set_key US-12587 NIL-0000  # Andrick Ponds State Wildlife Area
    set_key US-1259 KFF-1259  # Green River Lake State Park
    set_key US-1260 KFF-1260  # John James Audubon State Park
    set_key US-12600 KFF-6952  # Blackhoof River Wildlife Management Area
    set_key US-1261 KFF-1261  # Kincaid Lake State Park
    set_key US-1262 KFF-1262  # Kingdom Come State Park
    set_key US-12626 KFF-6958  # Indian Lake Wildlife Management Area
    set_key US-12627 KFF-6924  # Rice Lake Fish &amp; WIldlife Area
    set_key US-1263 KFF-1263  # Lake Malone State Park
    set_key US-12636 KFF-7308  # Jenness State Beach (Park)
    set_key US-12637 KFF-7387  # Wallis Sands State Park
    set_key US-1264 KFF-1264  # Levi Jackson Wilderness Road State Park
    set_key US-12645 KFF-5881  # Flatbrook Wildlife Management Area
    set_key US-1265 KFF-1265  # Lincoln Homestead State Park
    set_key US-1266 KFF-1266  # Mineral Mounds State Park
    set_key US-1267 KFF-1267  # My Old Kentucky Home State Park
    set_key US-1268 KFF-1268  # Nolin Lake State Park
    set_key US-12684 KFF-6975  # Indian Nations National Scenic and Wildlife Area
    set_key US-1269 KFF-1269  # Old Fort Harrod State Park
    set_key US-1270 KFF-1270  # Paintsville Lake State Park
    set_key US-12706 KFF-7219  # Marget Lake Wildlife Management Area
    set_key US-12708 KFF-7235  # Black River National Scenic River
    set_key US-1271 KFF-1271  # Taylorsville Lake State Park
    set_key US-12713 KFF-7159  # Fiery Gizzard State Park
    set_key US-12714 KFF-7160  # Head of the Crow State Park
    set_key US-12716 KFF-7157  # Hayfields State Park
    set_key US-1272 KFF-1272  # Yatesville Lake State Park
    set_key US-12728 KFF-7152  # Fall Creek Wildlife Habitat Management Area
    set_key US-12729 KFF-6978  # Spence &amp; Moriarity Wildlife Habitat Management Area
    set_key US-1273 KFF-1273  # Barren River Lake State Park
    set_key US-12736 KFF-7303  # Gifford Point Wildlife Management Area
    set_key US-1274 KFF-1274  # Blue Licks Battlefield State Park
    set_key US-1275 KFF-1275  # Buckhorn Lake State Park
    set_key US-12755 NIL-0000  # Sandsage State Wildlife Area
    set_key US-12756 KFF-7204  # Mountain Home Reservoir State Wildlife Area
    set_key US-1276 KFF-1276  # Carter Caves State Park
    set_key US-1277 KFF-1277  # Cumberland Falls State Park
    set_key US-1278 KFF-1278  # Dale Hollow State Park
    set_key US-12785 KFF-7310  # Rio Mora National Wildlife Refuge
    set_key US-12786 KFF-7234  # Au Sable River National Scenic River
    set_key US-1279 KFF-1279  # General Butler State Park
    set_key US-1280 KFF-1280  # Greenbo Lake State Park
    set_key US-12804 KFF-7311  # Valle de Oro National Wildlife Refuge
    set_key US-12809 KFF-7177  # Yucatan Wildlife Management Area
    set_key US-1281 KFF-1281  # Jenny Wiley State Park
    set_key US-12810 KFF-7178  # Choice Wildlife Management Area
    set_key US-12811 KFF-7218  # Beaver Creek Wildlife Management Area
    set_key US-12812 KFF-7216  # Root River Wildlife Management Area
    set_key US-1282 KFF-1282  # Kenlake State Park
    set_key US-1283 KFF-1283  # Kentucky Dam Village State Park
    set_key US-1284 KFF-1284  # Lake Barkley State Park
    set_key US-1285 KFF-1285  # Lake Cumberland State Park
    set_key US-1286 KFF-1286  # Natural Bridge State Park
    set_key US-1287 KFF-1287  # Pennyrile Forest State Park
    set_key US-1288 KFF-1288  # Pine Mountain State Park
    set_key US-1289 KFF-1289  # Rough River Dam State Park
    set_key US-1290 KFF-1290  # Bear Creek Lake State Park
    set_key US-1291 KFF-1291  # Belle Isle State Park
    set_key US-1292 KFF-1292  # Breaks Interstate State Park
    set_key US-1293 KFF-1293  # Caledon State Park
    set_key US-1294 KFF-1294  # Chippokes Plantation State Park
    set_key US-1295 KFF-1295  # Claytor Lake State Park
    set_key US-1296 KFF-1296  # Douthat State Park
    set_key US-1297 KFF-1297  # Fairy Stone State Park
    set_key US-1298 KFF-1298  # False Cape State Park
    set_key US-1299 KFF-1299  # First Landing State Park
    set_key US-1300 KFF-1300  # Grayson Highlands State Park
    set_key US-1301 KFF-1301  # High Bridge Trail State Park
    set_key US-13011 KFF-7481  # Shoal River Headwaters State Park
    set_key US-13015 KFF-7023  # Bruneau River Wildlife Management Area
    set_key US-1302 KFF-1302  # Holliday Lake State Park
    set_key US-13022 KFF-7055  # Alkali Lake Wildlife Management Area
    set_key US-1303 KFF-1303  # Hungry Mother State Park
    set_key US-1304 KFF-1304  # James River State Park
    set_key US-1305 KFF-1305  # Kiptopeke State Park
    set_key US-13057 KFF-5361  # Beaver Swamp Wildlife Management Area
    set_key US-13059 KFF-5877  # Abbotts Meadow Wildlife Management Area
    set_key US-1306 KFF-1306  # Lake Anna State Park
    set_key US-13061 KFF-5886  # Gum Tree Corner Wildlife Management Area
    set_key US-13064 KFF-7391  # Scripps Wildlife Management Area
    set_key US-1307 KFF-1307  # Leesylvania State Park
    set_key US-1308 KFF-1308  # Mason Neck State Park
    set_key US-13084 NIL-0000  # Ralston Creek State Wildlife Area
    set_key US-1309 KFF-1309  # Natural Tunnel State Park
    set_key US-1310 KFF-1310  # New River Trail State Park
    set_key US-1311 KFF-1311  # Occoneechee State Park
    set_key US-1312 KFF-1312  # Pocahontas State Park
    set_key US-1313 KFF-1313  # Powhatan State Park
    set_key US-1314 KFF-1314  # Sailor's Creek Battlefield State Park
    set_key US-1315 KFF-1315  # Seven Bends State Park
    set_key US-1316 KFF-1316  # Shenandoah River State Park
    set_key US-1317 KFF-1317  # Shot Tower State Park
    set_key US-1318 KFF-1318  # Sky Meadows State Park
    set_key US-1319 KFF-1319  # Smith Mountain Lake State Park
    set_key US-13198 KFF-7417  # Black River State Park
    set_key US-1320 KFF-1320  # Southwest Virginia Museum State Park
    set_key US-13201 KFF-7416  # Laurel Caverns State Park
    set_key US-1321 KFF-1321  # Staunton River State Park
    set_key US-1322 KFF-1322  # Staunton River Battlefield State Park
    set_key US-1323 KFF-1323  # Twin Lakes State Park
    set_key US-1324 KFF-1324  # Westmoreland State Park
    set_key US-1325 KFF-1325  # Wilderness Road State Park
    set_key US-1326 KFF-1326  # York River State Park
    set_key US-1327 KFF-1327  # Allegheny Islands State Park
    set_key US-1328 KFF-1328  # Archbald Pothole State Park
    set_key US-1329 KFF-1329  # Bald Eagle State Park
    set_key US-1330 KFF-1330  # Beltzville State Park
    set_key US-1331 KFF-1331  # Bendigo State Park
    set_key US-1332 KFF-1332  # Benjamin Rush State Park
    set_key US-1333 KFF-1333  # Big Pocono State Park
    set_key US-1334 KFF-1334  # Black Moshannon State Park
    set_key US-1335 KFF-1335  # Blue Knob State Park
    set_key US-1336 KFF-1336  # Buchanan's Birthplace State Park
    set_key US-13364 KFF-7449  # Cherokee Trail of Tears State Park
    set_key US-1337 KFF-1337  # Caledonia State Park
    set_key US-1338 KFF-1338  # Canoe Creek State Park
    set_key US-1339 KFF-1339  # Chapman State Park
    set_key US-1340 KFF-1340  # Cherry Springs State Park
    set_key US-1341 KFF-1341  # Clear Creek State Park
    set_key US-1342 KFF-1342  # Codorus State Park
    set_key US-1343 KFF-1343  # Colonel Denning State Park
    set_key US-1344 KFF-1344  # Colton Point State Park
    set_key US-1345 KFF-1345  # Cook Forest State Park
    set_key US-1346 KFF-1346  # Cowans Gap State Park
    set_key US-1347 KFF-1347  # Delaware Canal State Park
    set_key US-1348 KFF-1348  # Denton Hill State Park
    set_key US-1349 KFF-1349  # Elk State Park
    set_key US-1350 KFF-1350  # Erie Bluffs State Park
    set_key US-1351 KFF-1351  # Evansburg State Park
    set_key US-1352 KFF-1352  # Fort Washington State Park
    set_key US-1353 KFF-1353  # Fowlers Hollow State Park
    set_key US-1354 KFF-1354  # Frances Slocum State Park
    set_key US-1355 KFF-1355  # French Creek State Park
    set_key US-1356 KFF-1356  # Gifford Pinchot State Park
    set_key US-1357 KFF-1357  # Gouldsboro State Park
    set_key US-1358 KFF-1358  # Greenwood Furnace State Park
    set_key US-1359 KFF-1359  # Hickory Run State Park
    set_key US-1360 KFF-1360  # Hillman State Park
    set_key US-1361 KFF-1361  # Hills Creek State Park
    set_key US-1362 KFF-1362  # Hyner Run State Park
    set_key US-1363 KFF-1363  # Hyner View State Park
    set_key US-1364 KFF-1364  # Kettle Creek State Park
    set_key US-1365 KFF-1365  # Keystone State Park
    set_key US-1366 KFF-1366  # Kinzua Bridge State Park
    set_key US-1367 KFF-1367  # Kooser State Park
    set_key US-1368 KFF-1368  # Lackawanna State Park
    set_key US-1369 KFF-1369  # Laurel Hill State Park
    set_key US-1370 KFF-1370  # Laurel Mountain State Park
    set_key US-1371 KFF-1371  # Laurel Ridge State Park
    set_key US-1372 KFF-1372  # Laurel Summit State Park
    set_key US-1373 KFF-1373  # Lehigh Gorge State Park
    set_key US-1374 KFF-1374  # Leonard Harrison State Park
    set_key US-1375 KFF-1375  # Linn Run State Park
    set_key US-1376 KFF-1376  # Little Buffalo State Park
    set_key US-1377 KFF-1377  # Little Pine State Park
    set_key US-1378 KFF-1378  # Locust Lake State Park
    set_key US-1379 KFF-1379  # Lyman Run State Park
    set_key US-1380 KFF-1380  # Marsh Creek State Park
    set_key US-1381 KFF-1381  # Maurice K Goddard State Park
    set_key US-1382 KFF-1382  # McCalls Dam State Park
    set_key US-1383 KFF-1383  # McConnells Mill State Park
    set_key US-1384 KFF-1384  # Memorial Lake State Park
    set_key US-1385 KFF-1385  # Milton State Park
    set_key US-1386 KFF-1386  # Mont Alto State Park
    set_key US-1387 KFF-1387  # Moraine State Park
    set_key US-1388 KFF-1388  # Mt. Pisgah State Park
    set_key US-1389 KFF-1389  # Nescopeck State Park
    set_key US-1390 KFF-1390  # Neshaminy State Park
    set_key US-1391 KFF-1391  # Nockamixon State Park
    set_key US-1392 KFF-1392  # Ohiopyle State Park
    set_key US-1393 KFF-1393  # Oil Creek State Park
    set_key US-1394 KFF-1394  # Ole Bull State Park
    set_key US-1395 KFF-1395  # Parker Dam State Park
    set_key US-1396 KFF-1396  # Patterson State Park
    set_key US-1397 KFF-1397  # Penn-Roosevelt State Park
    set_key US-1398 KFF-1398  # Pine Grove Furnace State Park
    set_key US-1399 KFF-1399  # Poe Paddy State Park
    set_key US-1400 KFF-1400  # Poe Valley State Park
    set_key US-1401 KFF-1401  # Point State Park
    set_key US-1402 KFF-1402  # Presque Isle State Park
    set_key US-1403 KFF-1403  # Prince Gallitzin State Park
    set_key US-1404 KFF-1404  # Promised Land State Park
    set_key US-1405 KFF-1405  # Prompton State Park
    set_key US-1406 KFF-1406  # Prouty Place State Park
    set_key US-1407 KFF-1407  # Pymatuning State Park
    set_key US-1408 KFF-1408  # Raymond B Winter State Park
    set_key US-1409 KFF-1409  # Raccoon Creek State Park
    set_key US-1410 KFF-1410  # Ralph Stover State Park
    set_key US-1411 KFF-1411  # Ravensburg State Park
    set_key US-1412 KFF-1412  # Reeds Gap State Park
    set_key US-1413 KFF-1413  # Ricketts Glen State Park
    set_key US-1414 KFF-1414  # Ridley Creek State Park
    set_key US-1415 KFF-1415  # Ryerson Station State Park
    set_key US-1416 KFF-1416  # S B Elliott State Park
    set_key US-1417 KFF-1417  # Salt Springs State Park
    set_key US-1418 KFF-1418  # Samuel S Lewis State Park
    set_key US-1419 KFF-1419  # Sand Bridge State Park
    set_key US-1420 KFF-1420  # Shawnee State Park
    set_key US-1421 KFF-1421  # Shikellamy State Park
    set_key US-1422 KFF-1422  # Sinnemahoning State Park
    set_key US-1423 KFF-1423  # Sizerville State Park
    set_key US-1424 KFF-1424  # Susquehanna State Park
    set_key US-1425 KFF-1425  # Susquehannock State Park
    set_key US-1426 KFF-1426  # Swatara State Park
    set_key US-1427 KFF-1427  # Tobyhanna State Park
    set_key US-1428 KFF-1428  # Trough Creek State Park
    set_key US-1429 KFF-1429  # Tuscarora State Park
    set_key US-1430 KFF-1430  # Tyler State Park
    set_key US-1431 KFF-1431  # Upper Pine Bottom State Park
    set_key US-1432 KFF-1432  # Warriors' Path State Park
    set_key US-1433 KFF-1433  # Whipple Dam State Park
    set_key US-1434 KFF-1434  # Worlds End State Park
    set_key US-1435 KFF-1435  # Yellow Creek State Park
    set_key US-1436 KFF-1436  # Amnicon Falls State Park
    set_key US-1437 KFF-1437  # Aztalan State Park
    set_key US-1438 KFF-1438  # Belmont Mound State Park
    set_key US-1439 KFF-1439  # Big Bay State Park
    set_key US-1440 KFF-1440  # Big Foot Beach State Park
    set_key US-1441 KFF-1441  # Blue Mound State Park
    set_key US-1442 KFF-1442  # Brunet Island State Park
    set_key US-1443 KFF-1443  # Buckhorn State Park
    set_key US-1444 KFF-1444  # Campbellsport Drumlin State Park
    set_key US-1445 KFF-1445  # Copper Culture State Park
    set_key US-1446 KFF-1446  # Copper Falls State Park
    set_key US-1447 KFF-1447  # Council Grounds State Park
    set_key US-1448 KFF-1448  # Cross Plains State Park
    set_key US-1449 KFF-1449  # Devil's Lake State Park
    set_key US-1450 KFF-1450  # Grand Traverse Island State Park
    set_key US-1451 KFF-1451  # Governor Dodge State Park
    set_key US-1452 KFF-1452  # Governor Nelson State Park
    set_key US-1453 KFF-1453  # Governor Thompson State Park
    set_key US-1454 KFF-1454  # Harrington Beach State Park
    set_key US-1455 KFF-1455  # Hartman Creek State Park
    set_key US-1456 KFF-1456  # High Cliff State Park
    set_key US-1457 KFF-1457  # Kinnickinnic State Park
    set_key US-1458 KFF-1458  # Kohler-Andrae State Park
    set_key US-1459 KFF-1459  # Lake Kegonsa State Park
    set_key US-1460 KFF-1460  # Lake Wissota State Park
    set_key US-1461 KFF-1461  # Lakeshore State Park
    set_key US-1462 KFF-1462  # Merrick State Park
    set_key US-1463 KFF-1463  # Mill Bluff State Park
    set_key US-1464 KFF-1464  # Mirror Lake State Park
    set_key US-1465 KFF-1465  # Natural Bridge State Park
    set_key US-1466 KFF-1466  # Nelson Dewey State Park
    set_key US-1467 KFF-1467  # New Glarus Woods State Park
    set_key US-1468 KFF-1468  # Newport State Park
    set_key US-1469 KFF-1469  # Pattison State Park
    set_key US-1470 KFF-1470  # Peninsula State Park
    set_key US-1471 KFF-1471  # Perrot State Park
    set_key US-1472 KFF-1472  # Potawatomi State Park
    set_key US-1473 KFF-1473  # Rib Mountain State Park
    set_key US-1474 KFF-1474  # Roche-A-Cri State Park
    set_key US-1475 KFF-1475  # Rock Island State Park
    set_key US-1476 KFF-1476  # Rocky Arbor State Park
    set_key US-1477 KFF-1477  # Straight Lake State Park
    set_key US-1478 KFF-1478  # Tower Hill State Park
    set_key US-1479 KFF-1479  # Whitefish Dunes State Park
    set_key US-1480 KFF-1480  # Wildcat Mountain State Park
    set_key US-1481 KFF-1481  # Willow River State Park
    set_key US-1482 KFF-1482  # Wyalusing State Park
    set_key US-1483 KFF-1483  # Yellowstone Lake State Park
    set_key US-1484 KFF-1484  # Algonac State Park
    set_key US-1485 KFF-1485  # Aloha State Park
    set_key US-1486 KFF-1486  # Baraga State Park
    set_key US-1487 KFF-1487  # Belle Isle State Park
    set_key US-1488 KFF-1488  # Bewabic State Park
    set_key US-1489 KFF-1489  # Brimley State Park
    set_key US-1490 KFF-1490  # Burt Lake State Park
    set_key US-1491 KFF-1491  # Cheboygan State Park
    set_key US-1492 KFF-1492  # Clear Lake State Park
    set_key US-1493 KFF-1493  # Coldwater Lake State Park
    set_key US-1494 KFF-1494  # Craig Lake State Park
    set_key US-1495 KFF-1495  # Dodge #4 State Park
    set_key US-1496 KFF-1496  # Duck Lake State Park
    set_key US-1497 KFF-1497  # Fisherman's Island State Park
    set_key US-1498 KFF-1498  # Fort Michilimackinac State Park
    set_key US-1499 KFF-1499  # Grand Haven State Park
    set_key US-1500 KFF-1500  # Grand Mere State Park
    set_key US-1501 KFF-1501  # Harrisville State Park
    set_key US-1502 KFF-1502  # Hart-Montague Trail State Park
    set_key US-1503 KFF-1503  # Hartwick Pines State Park
    set_key US-1504 KFF-1504  # Hayes State Park
    set_key US-1505 KFF-1505  # Historic Mill Discovery State Park
    set_key US-1506 KFF-1506  # Hoeft State Park
    set_key US-1507 KFF-1507  # Hoffmaster State Park
    set_key US-1508 KFF-1508  # Holland State Park
    set_key US-1509 KFF-1509  # Indian Lake State Park
    set_key US-1510 KFF-1510  # Interlochen State Park
    set_key US-1511 KFF-1511  # Kal-Haven Trail State Park
    set_key US-1512 KFF-1512  # Lake Gogebic State Park
    set_key US-1513 KFF-1513  # Mike Levine Lakelands Trail State Park
    set_key US-1514 KFF-1514  # Lakeport State Park
    set_key US-1515 KFF-1515  # Leelanau State Park
    set_key US-1516 KFF-1516  # Ludington State Park
    set_key US-1517 KFF-1517  # Mackinac Island State Park
    set_key US-1518 KFF-1518  # Maybury State Park
    set_key US-1519 KFF-1519  # McLain State Park
    set_key US-1520 KFF-1520  # Mears State Park
    set_key US-1521 KFF-1521  # Meridian-Baseline State Park
    set_key US-1522 KFF-1522  # Milliken State Park
    set_key US-1523 KFF-1523  # Mitchell State Park
    set_key US-1524 KFF-1524  # Muskallonge Lake State Park
    set_key US-1525 KFF-1525  # Muskegon State Park
    set_key US-1526 KFF-1526  # Negwegon State Park
    set_key US-1527 KFF-1527  # Newaygo State Park
    set_key US-1528 KFF-1528  # North Higgins Lake State Park
    set_key US-1529 KFF-1529  # Onaway State Park
    set_key US-1530 KFF-1530  # Orchard Beach State Park
    set_key US-1531 KFF-1531  # Otsego Lake State Park
    set_key US-1532 KFF-1532  # Palms Book State Park
    set_key US-1533 KFF-1533  # Petoskey State Park
    set_key US-1534 KFF-1534  # Porcupine Mountains State Park
    set_key US-1535 KFF-1535  # Port Crescent State Park
    set_key US-1536 KFF-1536  # Saugatuck Dunes State Park
    set_key US-1537 KFF-1537  # Seven Lakes State Park
    set_key US-1538 KFF-1538  # Silver Lake State Park
    set_key US-1539 KFF-1539  # Sleeper State Park
    set_key US-1540 KFF-1540  # Sleepy Hollow State Park
    set_key US-1541 KFF-1541  # South Higgins Lake State Park
    set_key US-1542 KFF-1542  # Sterling State Park
    set_key US-1543 KFF-1543  # Straits State Park
    set_key US-1544 KFF-1544  # Tahquamenon Falls State Park
    set_key US-1545 KFF-1545  # Tawas Point State Park
    set_key US-1546 KFF-1546  # Thompson's Harbor State Park
    set_key US-1547 KFF-1547  # Traverse City State Park
    set_key US-1548 KFF-1548  # Twin Lakes State Park
    set_key US-1549 KFF-1549  # Van Buren State Park
    set_key US-1550 KFF-1550  # Van Buren Trail State Park
    set_key US-1551 KFF-1551  # Van Riper State Park
    set_key US-1552 KFF-1552  # Warren Dunes State Park
    set_key US-1553 KFF-1553  # Warren Woods State Park
    set_key US-1554 KFF-1554  # Wells State Park
    set_key US-1555 KFF-1555  # White Pine Trail State Park
    set_key US-1556 KFF-1556  # Wilderness State Park
    set_key US-1557 KFF-1557  # Wilson State Park
    set_key US-1558 KFF-1558  # Young State Park
    set_key US-1559 KFF-1559  # Assateague State Park
    set_key US-1560 KFF-1560  # Big Run State Park
    set_key US-1561 KFF-1561  # Bill Burton Fishing Pier State Park
    set_key US-1562 KFF-1562  # Calvert Cliffs State Park
    set_key US-1563 KFF-1563  # Casselman River Bridge State Park
    set_key US-1564 KFF-1564  # Chapel Point State Park
    set_key US-1565 KFF-1565  # Chapman State Park
    set_key US-1566 KFF-1566  # Cunningham Falls State Park
    set_key US-1567 KFF-1567  # Dans Mountain State Park
    set_key US-1568 KFF-1568  # Deep Creek Lake State Park
    set_key US-1569 KFF-1569  # Elk Neck State Park
    set_key US-1570 KFF-1570  # Fort Frederick State Park
    set_key US-1571 KFF-1571  # Fort Tonoloway State Park
    set_key US-1572 KFF-1572  # Franklin Point State Park
    set_key US-1573 KFF-1573  # Gambrill State Park
    set_key US-1574 KFF-1574  # Gathland State Park
    set_key US-1575 KFF-1575  # Greenbrier State Park
    set_key US-1576 KFF-1576  # Greenwell State Park
    set_key US-1577 KFF-1577  # Gunpowder Falls State Park
    set_key US-1578 KFF-1578  # Hart-Miller Island State Park
    set_key US-1579 KFF-1579  # Herrington Manor State Park
    set_key US-1580 KFF-1580  # Janes Island State Park
    set_key US-1581 KFF-1581  # Jonas Green State Park
    set_key US-1582 KFF-1582  # Martinak State Park
    set_key US-1583 KFF-1583  # Matthew Henson State Park
    set_key US-1584 KFF-1584  # New Germany State Park
    set_key US-1585 KFF-1585  # Newtowne Neck State Park
    set_key US-1586 KFF-1586  # North Point State Park
    set_key US-1587 KFF-1587  # Palmer State Park
    set_key US-1588 KFF-1588  # Patapsco Valley State Park
    set_key US-1589 KFF-1589  # Patuxent River State Park
    set_key US-1590 KFF-1590  # Point Lookout State Park
    set_key US-1591 KFF-5873  # Nanjemoy Wildlife Management Area
    set_key US-1592 KFF-1592  # Rocks State Park
    set_key US-1593 KFF-1593  # Rocky Gap State Park
    set_key US-1594 KFF-1594  # Rosaryville State Park
    set_key US-1595 KFF-1595  # Sandy Point State Park
    set_key US-1596 KFF-1596  # Seneca Creek State Park
    set_key US-1597 KFF-1597  # Smallwood State Park
    set_key US-1598 NIL-0000  # South Mountain State Park; WWFF candidates: KFF-1598, KFF-5012
    set_key US-1599 KFF-1599  # St. Clements Island State Park
    set_key US-1600 KFF-1600  # St. Mary's River State Park
    set_key US-1601 KFF-1601  # Susquehanna State Park
    set_key US-1602 KFF-1602  # Swallow Falls State Park
    set_key US-1603 KFF-1603  # Tuckahoe State Park
    set_key US-1604 KFF-1604  # Washington Monument State Park
    set_key US-1605 KFF-1605  # Wills Mountain State Park
    set_key US-1606 KFF-1606  # Wye Oak State Park
    set_key US-1607 KFF-1607  # Allaire State Park
    set_key US-1608 KFF-1608  # Allamuchy Mountain State Park
    set_key US-1609 KFF-1609  # Barnegat Lighthouse State Park
    set_key US-1610 KFF-1610  # Cape May Point State Park
    set_key US-1611 KFF-1611  # Cheesequake State Park
    set_key US-1612 KFF-1612  # Corson's Inlet State Park
    set_key US-1613 KFF-1613  # Delaware and Raritan Canal State Park
    set_key US-1614 KFF-1614  # Double Trouble State Park
    set_key US-1615 KFF-1615  # Thomas Edison Memorial State Park
    set_key US-1616 KFF-1616  # Farny State Park
    set_key US-1617 KFF-1617  # Fort Mott State Park
    set_key US-1618 KFF-1618  # Hacklebarney State Park
    set_key US-1619 KFF-1619  # High Point State Park
    set_key US-1620 KFF-1620  # Hopatcong State Park
    set_key US-1621 KFF-1621  # Island Beach State Park
    set_key US-1622 KFF-1622  # Kittatinny Valley State Park
    set_key US-1623 KFF-1623  # Liberty State Park
    set_key US-1624 KFF-1624  # Long Pond Ironworks State Park
    set_key US-1625 KFF-1625  # Monmouth Battlefield State Park
    set_key US-1626 KFF-1626  # Parvin State Park
    set_key US-1627 KFF-1627  # Pigeon Swamp State Park
    set_key US-1628 KFF-1628  # Princeton Battlefield State Park
    set_key US-1629 KFF-1629  # Rancocas State Park
    set_key US-1630 KFF-1630  # Ringwood State Park
    set_key US-1631 KFF-1631  # Stephens State Park
    set_key US-1632 KFF-1632  # Swartswood State Park
    set_key US-1633 KFF-1633  # Voorhees State Park
    set_key US-1634 KFF-1634  # Washington Crossing State Park
    set_key US-1635 KFF-1635  # Washington Rock State Park
    set_key US-1636 KFF-1636  # Wawayanda State Park
    set_key US-1637 KFF-1637  # Chugach State Park
    set_key US-1638 KFF-1638  # Kachemak Bay State Park
    set_key US-1639 KFF-1639  # Afognak Island State Park
    set_key US-1640 KFF-1640  # Shuyak Island State Park
    set_key US-1641 KFF-1641  # Denali State Park
    set_key US-1642 KFF-1642  # Chilkat State Park
    set_key US-1643 KFF-1643  # Point Bridget State Park
    set_key US-1644 KFF-1644  # Wood-Tikchik State Park
    set_key US-1645 KFF-1645  # Above All State Park
    set_key US-1646 KFF-1646  # Beaver Brook State Park
    set_key US-1647 KFF-1647  # Bennett's Pond State Park
    set_key US-1648 KFF-1648  # Bigelow Hollow State Park
    set_key US-1649 KFF-1649  # Black Rock State Park
    set_key US-1650 KFF-1650  # Bluff Point State Park
    set_key US-1651 KFF-1651  # Bolton Notch State Park
    set_key US-1652 KFF-1652  # Brainard Homestead State Park
    set_key US-1653 KFF-1653  # Burr Pond State Park
    set_key US-1654 KFF-1654  # Camp Columbia State Park
    set_key US-1655 KFF-1655  # Campbell Falls State Park
    set_key US-1656 KFF-1656  # Chatfield Hollow State Park
    set_key US-1657 KFF-1657  # Collis P. Huntington State Park
    set_key US-1658 KFF-1658  # Connecticut Valley Railroad State Park
    set_key US-1659 KFF-1659  # Dart Island State Park
    set_key US-1660 KFF-1660  # Day Pond State Park
    set_key US-1661 KFF-1661  # Dennis Hill State Park
    set_key US-1662 KFF-1662  # Devil's Hopyard State Park
    set_key US-1663 KFF-1663  # Dinosaur State Park
    set_key US-1664 KFF-1664  # Eagle Landing State Park
    set_key US-1665 KFF-1665  # Farm River State Park
    set_key US-1666 KFF-1666  # Fort Griswold Battlefield State Park
    set_key US-1667 KFF-1667  # Fort Trumbull State Park
    set_key US-1668 KFF-1668  # Gardner Lake State Park
    set_key US-1669 KFF-1669  # Gay City State Park
    set_key US-1670 KFF-1670  # George Dudley Seymour State Park
    set_key US-1671 KFF-1671  # George Waldo State Park
    set_key US-1672 KFF-1672  # Gillette Castle State Park
    set_key US-1673 KFF-1673  # Haddam Island State Park
    set_key US-1674 KFF-1674  # Haddam Meadows State Park
    set_key US-1675 KFF-1675  # Haley Farm State Park
    set_key US-1676 KFF-1676  # Hammonasset Beach State Beach
    set_key US-1677 KFF-1677  # Harkness Memorial State Park
    set_key US-1678 KFF-1678  # Haystack Mountain State Park
    set_key US-1679 KFF-1679  # Higganum Reservoir State Park
    set_key US-1680 KFF-1680  # Hopemead State Park
    set_key US-1681 KFF-1681  # Hopeville Pond State Park
    set_key US-1682 KFF-1682  # Housatonic Meadows State Park
    set_key US-1683 KFF-1683  # Hurd State Park
    set_key US-1684 KFF-1684  # Indian Well State Park
    set_key US-1685 KFF-1685  # John A. Minetto State Park
    set_key US-1686 KFF-1686  # Kent Falls State Park
    set_key US-1687 KFF-1687  # Kettletown State Park
    set_key US-1688 KFF-1688  # Killingly Pond State Park
    set_key US-1689 KFF-1689  # Lake Waramaug State Park
    set_key US-1690 KFF-1690  # Lamentation Mountain State Park
    set_key US-1691 KFF-1691  # Lovers Leap State Park
    set_key US-1692 KFF-1692  # Macedonia Brook State Park
    set_key US-1693 KFF-1693  # Machimoodus State Park
    set_key US-1694 KFF-1694  # Mansfield Hollow State Park
    set_key US-1695 KFF-1695  # Mashamoquet Brook State Park
    set_key US-1696 KFF-1696  # Mianus River State Park
    set_key US-1697 KFF-1697  # Millers Pond State Park
    set_key US-1698 KFF-1698  # Minnie Island State Park
    set_key US-1699 KFF-1699  # Mohawk Mountain State Park
    set_key US-1700 KFF-1700  # Mooween State Park
    set_key US-1701 KFF-1701  # Mount Bushnell State Park
    set_key US-1702 KFF-1702  # Mount Riga State Park
    set_key US-1703 KFF-1703  # Mount Tom State Park
    set_key US-1704 KFF-1704  # Old Furnace State Park
    set_key US-1705 KFF-1705  # Osborndale State Park
    set_key US-1706 KFF-1706  # Penwood State Park
    set_key US-1707 KFF-1707  # Putnam Memorial State Park
    set_key US-1708 KFF-1708  # Quaddick State Park
    set_key US-1709 KFF-1709  # Quinnipiac River State Park
    set_key US-1710 KFF-1710  # River Highlands State Park
    set_key US-1711 KFF-1711  # Rocky Neck State Park
    set_key US-1712 KFF-1712  # Ross Pond State Park
    set_key US-1713 KFF-1713  # Scantic River State Park
    set_key US-1714 KFF-1714  # Selden Neck State Park
    set_key US-1715 KFF-1715  # Sherwood Island State Park
    set_key US-1716 KFF-1716  # Silver Sands State Park
    set_key US-1717 KFF-1717  # Sleeping Giant State Park
    set_key US-1718 KFF-1718  # Southford Falls State Park
    set_key US-1719 KFF-1719  # Squantz Pond State Park
    set_key US-1720 KFF-1720  # Stillwater Pond State Park
    set_key US-1721 KFF-1721  # Stratton Brook State Park
    set_key US-1722 KFF-1722  # Sunny Brook State Park
    set_key US-1723 KFF-1723  # Sunrise State Park
    set_key US-1724 KFF-1724  # Talcott Mountain State Park
    set_key US-1725 KFF-1725  # Trimountain State Park
    set_key US-1726 KFF-1726  # Wadsworth Falls State Park
    set_key US-1727 KFF-1727  # West Rock Ridge State Park
    set_key US-1728 KFF-1728  # Wharton Brook State Park
    set_key US-1729 KFF-1729  # Windsor Meadows State Park
    set_key US-1730 KFF-1730  # Alapocas Run State Park
    set_key US-1731 KFF-1731  # Bellevue State Park
    set_key US-1732 KFF-1732  # Brandywine Creek State Park
    set_key US-1733 KFF-1733  # Cape Henlopen State Park
    set_key US-1734 KFF-1734  # Delaware Seashore State Park
    set_key US-1735 KFF-1735  # Fenwick Island State Park
    set_key US-1736 KFF-1736  # Fort Delaware State Park
    set_key US-1737 KFF-1737  # Fort DuPont State Park
    set_key US-1738 KFF-1738  # Fox Point State Park
    set_key US-1739 KFF-1739  # Holts Landing State Park
    set_key US-1740 KFF-1740  # Killens Pond State Park
    set_key US-1741 KFF-1741  # Lums Pond State Park
    set_key US-1742 KFF-1742  # Trap Pond State Park
    set_key US-1743 KFF-1743  # White Clay Creek State Park
    set_key US-1744 KFF-1744  # Wilmington State Park
    set_key US-1745 KFF-1745  # Babler Memorial State Park
    set_key US-1746 KFF-1746  # Sam A. Baker State Park
    set_key US-1747 KFF-1747  # Bennett Spring State Park
    set_key US-1748 KFF-1748  # Big Lake State Park
    set_key US-1749 KFF-1749  # Big Oak Tree State Park
    set_key US-1750 KFF-1750  # Big Sugar Creek State Park
    set_key US-1751 KFF-1751  # Castlewood State Park
    set_key US-1752 KFF-1752  # Crowder State Park
    set_key US-1753 KFF-1753  # Cuivre River State Park
    set_key US-1754 KFF-1754  # Current River State Park
    set_key US-1755 KFF-1755  # Don Robinson State Park
    set_key US-1756 KFF-1756  # Echo Bluff State Park
    set_key US-1757 KFF-1757  # Elephant Rocks State Park
    set_key US-1758 KFF-1758  # Finger Lakes State Park
    set_key US-1759 KFF-1759  # Graham Cave State Park
    set_key US-1760 KFF-1760  # Grand Gulf State Park
    set_key US-1761 KFF-1761  # Ha Ha Tonka State Park
    set_key US-1762 KFF-1762  # Harry S Truman State Park
    set_key US-1763 KFF-1763  # Hawn State Park
    set_key US-1764 KFF-1764  # Johnson's Shut-Ins State Park
    set_key US-1765 KFF-1765  # Jones-Confluence Point State Park
    set_key US-1766 KFF-1766  # Katy Trail State Park
    set_key US-1767 KFF-1767  # Knob Noster State Park
    set_key US-1768 KFF-1768  # Lake of the Ozarks State Park
    set_key US-1769 KFF-1769  # Lake Wappapello State Park
    set_key US-1770 KFF-1770  # Lewis and Clark State Park
    set_key US-1771 KFF-1771  # Long Branch State Park
    set_key US-1772 KFF-1772  # Mark Twain State Park
    set_key US-1773 KFF-1773  # Meramec State Park
    set_key US-1774 KFF-1774  # Montauk State Park
    set_key US-1775 KFF-1775  # Morris State Park
    set_key US-1776 KFF-1776  # Onondaga Cave State Park
    set_key US-1777 KFF-1777  # Pershing State Park
    set_key US-1778 KFF-1778  # Pomme de Terre State Park
    set_key US-1779 KFF-1779  # Prairie State Park
    set_key US-1780 KFF-1780  # Roaring River State Park
    set_key US-1781 KFF-1781  # Robertsville State Park
    set_key US-1782 KFF-1782  # Rock Bridge Memorial State Park
    set_key US-1783 KFF-1783  # Route 66 State Park
    set_key US-1784 KFF-1784  # St. Francois State Park
    set_key US-1785 KFF-1785  # St. Joe State Park
    set_key US-1786 KFF-1786  # Stockton State Park
    set_key US-1787 KFF-1787  # Table Rock State Park
    set_key US-1788 KFF-1788  # Taum Sauk Mountain State Park
    set_key US-1789 KFF-1789  # Thousand Hills State Park
    set_key US-1790 KFF-1790  # Trail of Tears State Park
    set_key US-1791 KFF-1791  # Van Meter State Park
    set_key US-1792 KFF-1792  # Wakonda State Park
    set_key US-1793 KFF-1793  # Wallace State Park
    set_key US-1794 KFF-1794  # Washington State Park
    set_key US-1795 KFF-1795  # Watkins Mill State Park
    set_key US-1796 KFF-1796  # Weston Bend State Park
    set_key US-1797 KFF-1797  # Audra State Park
    set_key US-1798 KFF-1798  # Babcock State Park
    set_key US-1799 KFF-1799  # Beartown State Park
    set_key US-1800 KFF-1800  # Beech Fork State Park
    set_key US-1801 KFF-1801  # Berkeley Springs State Park
    set_key US-1802 KFF-1802  # Blackwater Falls State Park
    set_key US-1803 KFF-1803  # Blennerhassett Island State Park
    set_key US-1804 KFF-1804  # Bluestone State Park
    set_key US-1805 KFF-1805  # Cacapon Resort State Park
    set_key US-1806 KFF-1806  # Canaan Valley Resort State Park
    set_key US-1807 KFF-1807  # Carnifex Ferry Battlefield State Park
    set_key US-1808 KFF-1808  # Cass Scenic Railroad State Park
    set_key US-1809 KFF-1809  # Cedar Creek State Park
    set_key US-1810 KFF-1810  # Chief Logan State Park
    set_key US-1811 KFF-1811  # Droop Mountain Battlefield State Park
    set_key US-1812 KFF-1812  # Fairfax Stone State Park
    set_key US-1813 KFF-1813  # Hawks Nest State Park
    set_key US-1814 KFF-1814  # Holly River State Park
    set_key US-1815 KFF-1815  # Little Beaver State Park
    set_key US-1816 KFF-1816  # Lost River State Park
    set_key US-1817 KFF-1817  # Moncove Lake State Park
    set_key US-1818 KFF-1818  # North Bend State Park
    set_key US-1819 KFF-1819  # Pinnacle Rock State Park
    set_key US-1820 KFF-1820  # Pipestem Resort State Park
    set_key US-1821 KFF-1821  # Pricketts Fort State Park
    set_key US-1822 KFF-1822  # Stonewall Jackson State Park
    set_key US-1823 KFF-1823  # Tu-Endie-Wei State Park
    set_key US-1824 KFF-1824  # Twin Falls Resort State Park
    set_key US-1825 KFF-1825  # Tygart Lake State Park
    set_key US-1826 KFF-1826  # Valley Falls State Park
    set_key US-1827 KFF-1827  # Watoga State Park
    set_key US-1828 KFF-1828  # Watters Smith Memorial State Park
    set_key US-1829 KFF-1829  # Alafia River State Park
    set_key US-1830 KFF-1830  # Alfred B.Maclay Gardens State Park
    set_key US-1831 KFF-1831  # Amelia Island State Park
    set_key US-1832 KFF-1832  # Anastasia State Park
    set_key US-1833 KFF-1833  # Avalon State Park
    set_key US-1834 KFF-1834  # Bahia Honda State Park
    set_key US-1835 KFF-1835  # Bald Point State Park
    set_key US-1836 KFF-1836  # Barnacle State Park
    set_key US-1837 KFF-1837  # Big Lagoon State Park
    set_key US-1838 KFF-1838  # Big Shoals State Park
    set_key US-1839 KFF-1839  # Big Talbot Island State Park
    set_key US-1840 KFF-1840  # Bill Baggs Cape Florida State Park
    set_key US-1841 KFF-1841  # Blackwater River State Park
    set_key US-1842 KFF-1842  # Blue Spring State Park
    set_key US-1843 KFF-1843  # Bulow Creek State Park
    set_key US-1844 KFF-1844  # Caladesi Island State Park
    set_key US-1845 KFF-1845  # Camp Helen State Park
    set_key US-1846 KFF-1846  # Cayo Costa State Park
    set_key US-1847 KFF-1847  # Collier-Seminole State Park
    set_key US-1848 KFF-1848  # Colt Creek State Park
    set_key US-1849 KFF-1849  # Constitution Convention Museum State Park
    set_key US-1850 KFF-1850  # Crystal River Archaeological State Park
    set_key US-1851 KFF-1851  # Curry Hammock State Park
    set_key US-1852 KFF-1852  # Dagny Johnson Key Largo Hammock Botanical State Park
    set_key US-1853 KFF-1853  # De Leon Springs State Park
    set_key US-1854 KFF-1854  # Deer Lake State Park
    set_key US-1855 KFF-1855  # Delnor-Wiggins Pass State Park
    set_key US-1856 KFF-1856  # Devil's Millhopper Geological State Park
    set_key US-1857 KFF-1857  # Don Pedro Island State Park
    set_key US-1858 KFF-1858  # Dr. Von D. Mizell-Eula Johnson State Park
    set_key US-1859 KFF-1859  # Dunns Creek State Park
    set_key US-1860 KFF-1860  # Econfina River State Park
    set_key US-1861 KFF-1861  # Eden Gardens State Park
    set_key US-1862 KFF-1862  # Edward Ball Wakulla Springs State Park
    set_key US-1863 KFF-1863  # Egmont Key State Park
    set_key US-1864 KFF-1864  # Falling Waters State Park
    set_key US-1865 KFF-1865  # Fanning Springs State Park
    set_key US-1866 KFF-1866  # Faver-Dykes State Park
    set_key US-1867 KFF-1867  # Florida Caverns State Park
    set_key US-1868 KFF-1868  # Forest Capital Museum State Park
    set_key US-1869 KFF-1869  # Fort Clinch State Park
    set_key US-1870 KFF-1870  # Fort Cooper State Park
    set_key US-1871 KFF-1871  # Fort George Island Cultural State Park
    set_key US-1872 KFF-1872  # Fort Pierce Inlet State Park
    set_key US-1873 KFF-1873  # Fred Gannon Rocky Bayou State Park
    set_key US-1874 KFF-1874  # Gasparilla Island State Park
    set_key US-1875 KFF-1875  # Grayton Beach State Park
    set_key US-1876 KFF-1876  # Henderson Beach State Park
    set_key US-1877 KFF-1877  # Highlands Hammock State Park
    set_key US-1878 KFF-1878  # Hillsborough River State Park
    set_key US-1879 KFF-1879  # Homosassa Springs Wildlife State Park
    set_key US-1880 KFF-1880  # Honeymoon Island State Park
    set_key US-1881 KFF-1881  # Hontoon Island State Park
    set_key US-1882 KFF-1882  # Hugh Taylor Birch State Park
    set_key US-1883 KFF-1883  # Ichetucknee Springs State Park
    set_key US-1884 KFF-1884  # John D. MacArthur Beach State Park
    set_key US-1885 KFF-1885  # John Gorrie Museum State Park
    set_key US-1886 KFF-1886  # John Pennekamp Coral Reef State Park
    set_key US-1887 KFF-1887  # Jonathan Dickinson State Park
    set_key US-1888 KFF-1888  # Lafayette Blue Springs State Park
    set_key US-1889 KFF-1889  # Lake Griffin State Park
    set_key US-1890 KFF-1890  # Lake Jackson Mounds Archaeological State Park
    set_key US-1891 KFF-1891  # Lake June-in-Winter Scrub State Park
    set_key US-1892 KFF-1892  # Lake Kissimmee State Park
    set_key US-1893 KFF-1893  # Lake Louisa State Park
    set_key US-1894 KFF-1894  # Lake Manatee State Park
    set_key US-1895 KFF-1895  # Lake Talquin State Park
    set_key US-1896 KFF-1896  # Letchworth-Love Mounds State Park
    set_key US-1897 KFF-1897  # Lignumvitae Key Botanical State Park
    set_key US-1898 KFF-1898  # Little Manatee River State Park
    set_key US-1899 KFF-1899  # Long Key State Park
    set_key US-1900 KFF-1900  # Lovers Key State Park
    set_key US-1901 KFF-1901  # Manatee Springs State Park
    set_key US-1902 KFF-1902  # Mike Roess Gold Head Branch State Park
    set_key US-1903 KFF-1903  # Mound Key Archaeological State Park
    set_key US-1904 KFF-1904  # Myakka River State Park
    set_key US-1905 KFF-1905  # North Peninsula State Park
    set_key US-1906 KFF-1906  # O'Leno State Park
    set_key US-1907 KFF-1907  # Ochlockonee River State Park
    set_key US-1908 KFF-1908  # Oleta River State Park
    set_key US-1909 KFF-1909  # Oscar Scherer State Park
    set_key US-1910 KFF-1910  # Perdido Key State Park
    set_key US-1911 KFF-1911  # Ponce De Leon Springs State Park
    set_key US-1912 KFF-1912  # Rainbow Springs State Park
    set_key US-1913 KFF-1913  # Ravine Gardens State Park
    set_key US-1914 KFF-1914  # Sebastian Inlet State Park
    set_key US-1915 KFF-1915  # Silver Springs State Park
    set_key US-1916 KFF-1916  # Skyway Fishing Pier State Park
    set_key US-1917 KFF-1917  # St. Andrews State Park
    set_key US-1918 KFF-1918  # St. Joseph Peninsula State Park
    set_key US-1919 KFF-1919  # Stephen Foster Folk Culture Center State Park
    set_key US-1920 KFF-1920  # Stump Pass Beach State Park
    set_key US-1921 KFF-1921  # Suwannee River State Park
    set_key US-1922 KFF-1922  # Three Rivers State Park
    set_key US-1923 KFF-1923  # Tomoka State Park
    set_key US-1924 KFF-1924  # Torreya State Park
    set_key US-1925 KFF-1925  # Troy Springs State Park
    set_key US-1926 KFF-1926  # Washington Oaks Gardens State Park
    set_key US-1927 KFF-1927  # Wekiwa Springs State Park
    set_key US-1928 KFF-1928  # Werner-Boyce Salt Springs State Park
    set_key US-1929 KFF-1929  # Wes Skiles Peacock Springs State Park
    set_key US-1930 KFF-1930  # Windley Key Fossil Reef Geological State Park
    set_key US-1931 KFF-1931  # A.W. Marion State Park
    set_key US-1932 KFF-1932  # Adams Lake State Park
    set_key US-1933 KFF-1933  # Alum Creek State Park
    set_key US-1934 KFF-1934  # Barkcamp State Park
    set_key US-1935 KFF-1935  # Beaver Creek State Park
    set_key US-1936 KFF-1936  # Blue Rock State Park
    set_key US-1937 KFF-1937  # Buck Creek State Park
    set_key US-1938 KFF-1938  # Buckeye Lake State Park
    set_key US-1939 KFF-1939  # Burr Oak State Park
    set_key US-1940 KFF-1940  # Caesar Creek State Park
    set_key US-1941 KFF-1941  # Catawba Island State Park
    set_key US-1942 KFF-1942  # Cleveland Lakefront State Park
    set_key US-1943 KFF-1943  # Cowan Lake State Park
    set_key US-1944 KFF-1944  # Magee Marsh State Wildlife Area
    set_key US-1945 KFF-1945  # Deer Creek State Park
    set_key US-1946 KFF-1946  # Delaware State Park
    set_key US-1947 KFF-1947  # Dillon State Park
    set_key US-1948 KFF-1948  # East Fork State Park
    set_key US-1949 KFF-1949  # East Harbor State Park
    set_key US-1950 KFF-1950  # Findley State Park
    set_key US-1951 KFF-1951  # Forked Run State Park
    set_key US-1952 KFF-1952  # Geneva State Park
    set_key US-1953 KFF-1953  # Grand Lake Saint Marys State Park
    set_key US-1954 KFF-1954  # Great Seal State Park
    set_key US-1955 KFF-1955  # Guilford Lake State Park
    set_key US-1956 KFF-1956  # Harrison Lake State Park
    set_key US-1957 KFF-1957  # Headlands Beach State Park
    set_key US-1958 KFF-1958  # Hocking Hills State Park
    set_key US-1959 KFF-1959  # Hueston Woods State Park
    set_key US-1960 KFF-1960  # Independence Dam State Park
    set_key US-1961 KFF-1961  # Indian Lake State Park
    set_key US-1962 KFF-1962  # Jackson Lake State Park
    set_key US-1963 KFF-1963  # Jefferson Lake State Park
    set_key US-1964 KFF-1964  # John Bryan State Park
    set_key US-1965 KFF-1965  # Kelleys Island State Park
    set_key US-1966 KFF-1966  # Kiser Lake State Park
    set_key US-1967 KFF-1967  # Lake Alma State Park
    set_key US-1968 KFF-1968  # Lake Hope State Park
    set_key US-1969 KFF-1969  # Lake Logan State Park
    set_key US-1970 KFF-1970  # Lake Loramie State Park
    set_key US-1971 KFF-1971  # Lake White State Park
    set_key US-1972 KFF-1972  # Little Miami State Park
    set_key US-1973 KFF-1973  # Madison Lake State Park
    set_key US-1974 KFF-1974  # Malabar Farm State Park
    set_key US-1975 KFF-1975  # Mary Jane Thurston State Park
    set_key US-1976 KFF-1976  # Maumee Bay State Park
    set_key US-1977 KFF-1977  # Mohican State Park
    set_key US-1978 KFF-1978  # Mosquito Lake State Park
    set_key US-1979 KFF-1979  # Mt. Gilead State Park
    set_key US-1980 KFF-1980  # Nelson-Kennedy Ledges State Park
    set_key US-1981 KFF-1981  # Oak Point State Park
    set_key US-1982 KFF-1982  # Paint Creek State Park
    set_key US-1983 KFF-1983  # Pike Lake State Park
    set_key US-1984 KFF-1984  # Portage Lakes State Park
    set_key US-1985 KFF-1985  # Punderson State Park
    set_key US-1986 KFF-1986  # Pymatuning of Ohio State Park
    set_key US-1987 KFF-1987  # Quail Hollow State Park
    set_key US-1988 KFF-1988  # Rocky Fork State Park
    set_key US-1989 KFF-1989  # Salt Fork State Park
    set_key US-1990 KFF-1990  # Scioto Trail State Park
    set_key US-1991 KFF-1991  # Shawnee State Park
    set_key US-1992 KFF-1992  # South Bass Island State Park
    set_key US-1993 KFF-1993  # Stonelick State Park
    set_key US-1994 KFF-1994  # Strouds Run State Park
    set_key US-1995 KFF-1995  # Sycamore State Park
    set_key US-1996 KFF-1996  # Tar Hollow State Park
    set_key US-1997 KFF-1997  # Tinker's Creek State Park
    set_key US-1998 KFF-1998  # Van Buren State Park
    set_key US-1999 KFF-1999  # West Branch State Park
    set_key US-2000 KFF-2000  # Wolf Run State Park
    set_key US-2001 KFF-2001  # Adirondack State Park
    set_key US-2002 KFF-2002  # Allan H Treman State Park
    set_key US-2003 KFF-2003  # Allegany State Park
    set_key US-2004 KFF-2004  # Amherst State Park
    set_key US-2005 KFF-2005  # Amsterdam Beach State Park
    set_key US-2006 KFF-2006  # Artpark State Park
    set_key US-2007 KFF-2007  # Battle Island State Park
    set_key US-2008 KFF-2008  # Bayard Cutting Arboretum State Park
    set_key US-2009 KFF-2009  # Bayswater Point State Park
    set_key US-2010 KFF-2010  # Bear Mountain State Park
    set_key US-2011 KFF-2011  # Beaver Island State Park
    set_key US-2012 KFF-2012  # Beechwood State Park
    set_key US-2013 KFF-2013  # Belmont Lake State Park
    set_key US-2014 KFF-2014  # Bethpage State Park
    set_key US-2015 KFF-2015  # Betty and Wilbur Davis State Park
    set_key US-2016 KFF-2016  # Blauvelt State Park
    set_key US-2017 KFF-2017  # Bowman Lake State Park
    set_key US-2018 KFF-2018  # Brentwood State Park
    set_key US-2019 KFF-2019  # Brookhaven State Park
    set_key US-2020 KFF-2020  # Buckhorn Island State Park
    set_key US-2021 KFF-2021  # Buffalo Harbor State Park
    set_key US-2022 KFF-2022  # Burnham Point State Park
    set_key US-2023 KFF-2023  # Buttermilk Falls State Park
    set_key US-2024 KFF-2024  # Caleb Smith State Park
    set_key US-2025 KFF-2025  # Camp Hero State Park
    set_key US-2026 KFF-2026  # Canandaigua Lake State Park
    set_key US-2027 KFF-2027  # Canoe-Picnic Point State Park
    set_key US-2028 KFF-2028  # Captree State Park
    set_key US-2029 KFF-2029  # Cayuga Lake State Park
    set_key US-2030 KFF-2030  # Cedar Island State Park
    set_key US-2031 KFF-2031  # Cedar Point State Park
    set_key US-2032 KFF-2032  # Chenango Valley State Park
    set_key US-2033 KFF-2033  # Cherry Plain State Park
    set_key US-2034 KFF-2034  # Chimney Bluffs State Park
    set_key US-2035 KFF-2035  # Chittenango Falls State Park
    set_key US-2036 KFF-2036  # Clarence Fahnestock State Park
    set_key US-2037 KFF-2037  # Clark Reservation State Park
    set_key US-2038 KFF-2038  # Cold Spring Harbor State Park
    set_key US-2039 KFF-2039  # Coles Creek State Park
    set_key US-2040 KFF-2040  # Crab Island State Park
    set_key US-2041 KFF-2041  # Croil Island State Park
    set_key US-2042 KFF-2042  # Cumberland Bay State Park
    set_key US-2043 KFF-2043  # Darien Lakes State Park
    set_key US-2044 KFF-2044  # De Veaux Woods State Park
    set_key US-2045 KFF-2045  # Delta Lake State Park
    set_key US-2046 KFF-2046  # Devil's Hole State Park
    set_key US-2047 KFF-2047  # Dewolf Point State Park
    set_key US-2048 KFF-2048  # Donald J. Trump State Park
    set_key US-2049 KFF-2049  # Marsha P. Johnson State Park
    set_key US-2050 KFF-2050  # Eel Weir State Park
    set_key US-2051 KFF-2051  # Evangola State Park
    set_key US-2052 KFF-2052  # Fair Haven Beach State Park
    set_key US-2053 KFF-2053  # Fillmore Glen State Park
    set_key US-2054 KFF-2054  # Fort Niagara State Park
    set_key US-2055 KFF-2055  # Four Mile Creek State Park
    set_key US-2056 KFF-2056  # Franklin D. Roosevelt State Park
    set_key US-2057 KFF-2057  # Franny Reese State Park
    set_key US-2058 KFF-2058  # Galop Island State Park
    set_key US-2059 KFF-2059  # Gantry Plaza State Park
    set_key US-2060 KFF-2060  # Gilbert Lake State Park
    set_key US-2061 KFF-2061  # Gilgo State Park
    set_key US-2062 KFF-2062  # Glimmerglass State Park
    set_key US-2063 KFF-2063  # Golden Hill State Park
    set_key US-2064 KFF-2064  # Goose Pond Mountain State Park
    set_key US-2065 KFF-2065  # Grafton Lakes State Park
    set_key US-2066 KFF-2066  # Grass Point State Park
    set_key US-2067 KFF-2067  # Green Lakes State Park
    set_key US-2068 KFF-2068  # Hamlin Beach State Park
    set_key US-2069 KFF-2069  # Harriman State Park
    set_key US-2070 KFF-2070  # Heckscher State Park
    set_key US-2071 KFF-2071  # Helen L. McNitt State Park
    set_key US-2072 KFF-2072  # Hempstead Lake State Park
    set_key US-2073 KFF-2073  # High Tor State Park
    set_key US-2074 KFF-2074  # Highland Lakes State Park
    set_key US-2075 KFF-2075  # Higley Flow State Park
    set_key US-2076 KFF-2076  # Hither Hills State Park
    set_key US-2077 KFF-2077  # Honeoye Lake State Park
    set_key US-2078 KFF-2078  # Hook Mountain State Park
    set_key US-2079 KFF-2079  # Hudson Highlands State Park
    set_key US-2080 KFF-2080  # Hudson River Islands State Park
    set_key US-2081 KFF-2081  # Iona Island State Park
    set_key US-2082 KFF-2082  # Irondequoit Bay Marine State Park
    set_key US-2083 KFF-2083  # Jacques Cartier State Park
    set_key US-2084 KFF-2084  # James Baird State Park
    set_key US-2085 KFF-2085  # John Boyd Thacher State Park
    set_key US-2086 KFF-2086  # Jones Beach State Park
    set_key US-2087 KFF-2087  # Joseph Davis State Park
    set_key US-2088 KFF-2088  # Keewaydin State Park
    set_key US-2089 KFF-2089  # Keuka Lake State Park
    set_key US-2090 KFF-2090  # Knox Farm State Park
    set_key US-2091 KFF-2091  # Kring Point State Park
    set_key US-2092 KFF-2092  # Lake Erie State Park
    set_key US-2093 KFF-2093  # Lake Superior State Park
    set_key US-2094 KFF-2094  # Lake Taghkanic State Park
    set_key US-2095 KFF-2095  # Lakeside State Park
    set_key US-2096 KFF-2096  # Letchworth State Park
    set_key US-2097 KFF-2097  # Lock 32 Canal State Park
    set_key US-2098 KFF-2098  # Lodi Point State Park
    set_key US-2099 KFF-2099  # Long Point State Park
    set_key US-2100 KFF-2100  # Macomb Reservation State Park
    set_key US-2101 KFF-2101  # Mills Norrie State Park
    set_key US-2102 KFF-2102  # Mark Twain State Park
    set_key US-2103 KFF-2103  # Mary Island State Park
    set_key US-2104 KFF-2104  # Max V. Shaul State Park
    set_key US-2105 KFF-2105  # Mexico Point State Park
    set_key US-2106 KFF-2106  # Midway State Park
    set_key US-2107 KFF-2107  # Mine Kill State Park
    set_key US-2108 KFF-2108  # Montauk Downs State Park
    set_key US-2109 KFF-2109  # Montauk Point State Park
    set_key US-2110 KFF-2110  # Moreau Lake State Park
    set_key US-2111 KFF-2111  # Napeague State Park
    set_key US-2112 KFF-2112  # Newtown Battlefield State Park
    set_key US-2113 KFF-2113  # Niagara Falls State Park
    set_key US-2114 KFF-2114  # Nissequogue River State Park
    set_key US-2115 KFF-2115  # Nyack Beach State Park
    set_key US-2116 KFF-2116  # Oak Orchard Marine State Park
    set_key US-2117 KFF-2117  # Ogden and Ruth Livingston Mills State Park
    set_key US-2118 KFF-2118  # Oquaga Creek State Park
    set_key US-2119 KFF-2119  # Orient Beach State Park
    set_key US-2120 KFF-2120  # Peebles Island State Park
    set_key US-2121 KFF-2121  # Pinnacle State Park
    set_key US-2122 KFF-2122  # Pixley Falls State Park
    set_key US-2123 KFF-2123  # Point Au Roche State Park
    set_key US-2124 KFF-2124  # Reservoir State Park
    set_key US-2125 KFF-2125  # Riverbank State Park
    set_key US-2126 KFF-2126  # Robert Wehle State Park
    set_key US-2127 KFF-2127  # Robert H. Treman State Park
    set_key US-2128 KFF-2128  # Robert Moses State Park
    set_key US-2129 KFF-2129  # Robert V. Riddell State Park
    set_key US-2130 KFF-2130  # Roberto Clemente State Park
    set_key US-2131 KFF-2131  # Rock Island Lighthouse State Park
    set_key US-2132 KFF-2132  # Rockland Lake State Park
    set_key US-2133 KFF-2133  # Sampson State Park
    set_key US-2134 KFF-2134  # Sandy Island Beach State Park
    set_key US-2135 KFF-2135  # Saratoga Spa State Park
    set_key US-2136 KFF-2136  # Schodack Island State Park
    set_key US-2137 KFF-2137  # Schunnemunk Mountain State Park
    set_key US-2138 KFF-2138  # Selkirk Shores State Park
    set_key US-2139 KFF-2139  # Seneca Lake State Park
    set_key US-2140 KFF-2140  # Shadmoor State Park
    set_key US-2141 KFF-2141  # Silver Lake State Park
    set_key US-2142 KFF-2142  # Southwick Beach State Park
    set_key US-2144 KFF-2144  # Sterling Forest State Park
    set_key US-2145 KFF-2145  # Stony Brook State Park
    set_key US-2146 KFF-2146  # Storm King State Park
    set_key US-2147 KFF-2147  # Sunken Meadow State Park
    set_key US-2148 KFF-2148  # Taconic State Park
    set_key US-2149 KFF-2149  # Tallman Mountain State Park
    set_key US-2150 KFF-2150  # Taughannock Falls State Park
    set_key US-2151 KFF-2151  # Thompsons Lake State Park
    set_key US-2152 KFF-2152  # Trail View State Park
    set_key US-2153 KFF-2153  # Valley Stream State Park
    set_key US-2154 KFF-2154  # Verona Beach State Park
    set_key US-2155 KFF-2155  # Waterson Point State Park
    set_key US-2156 KFF-2156  # Watkins Glen State Park
    set_key US-2157 KFF-2157  # Wellesley Island State Park
    set_key US-2158 KFF-2158  # Westcott Beach State Park
    set_key US-2159 KFF-2159  # Whetstone Gulf State Park
    set_key US-2160 KFF-2160  # Whirlpool State Park
    set_key US-2161 KFF-2161  # Wildwood State Park
    set_key US-2162 KFF-2162  # Wilson Tuscarora State Park
    set_key US-2163 KFF-2163  # Wonder Lake State Park
    set_key US-2164 KFF-2164  # Woodlawn Beach State Park
    set_key US-2165 KFF-2165  # A. H. Stephens State Park
    set_key US-2166 KFF-2166  # Amicalola Falls State Park
    set_key US-2167 KFF-2167  # Black Rock Mountain State Park
    set_key US-2168 KFF-2168  # Chattahoochee Bend State Park
    set_key US-2169 KFF-2169  # Cloudland Canyon State Park
    set_key US-2170 KFF-2170  # Crooked River State Park
    set_key US-2171 KFF-2171  # Don Carter State Park
    set_key US-2172 KFF-2172  # Elijah Clark State Park
    set_key US-2173 KFF-2173  # F.D. Roosevelt State Park
    set_key US-2174 KFF-2174  # Florence Marina State Park
    set_key US-2175 KFF-2175  # Fort McAllister State Park
    set_key US-2176 KFF-2176  # Fort Mountain State Park
    set_key US-2177 KFF-2177  # Fort Yargo State Park
    set_key US-2178 KFF-2178  # General Coffee State Park
    set_key US-2179 KFF-2179  # George L. Smith State Park
    set_key US-2180 KFF-2180  # George T. Bagby and Lodge State Park
    set_key US-2181 KFF-2181  # Georgia Veterans State Park
    set_key US-2182 KFF-2182  # Jack Hill State Park (Gordonia Altamaha)
    set_key US-2183 KFF-2183  # Hamburg State Park
    set_key US-2184 KFF-2184  # Hard Labor Creek State Park
    set_key US-2185 KFF-2185  # High Falls State Park
    set_key US-2186 KFF-2186  # Indian Springs State Park
    set_key US-2187 KFF-2187  # James H. (Sloppy) Floyd State Park
    set_key US-2188 KFF-2188  # Laura S. Walker State Park
    set_key US-2189 KFF-2189  # Little Ocmulgee State Park
    set_key US-2190 KFF-2190  # Magnolia Springs State Park
    set_key US-2191 KFF-2191  # Mistletoe State Park
    set_key US-2192 KFF-2192  # Moccasin Creek State Park
    set_key US-2193 KFF-2193  # Panola Mountain State Park
    set_key US-2194 KFF-2194  # Red Top Mountain State Park
    set_key US-2195 KFF-2195  # Reed Bingham State Park
    set_key US-2196 KFF-2196  # Richard B. Russell State Park
    set_key US-2197 KFF-2197  # Seminole State Park
    set_key US-2198 KFF-2198  # Skidaway Island State Park
    set_key US-2199 KFF-2199  # Smithgall Woods State Park
    set_key US-2200 KFF-2200  # Stephen C Foster State Park
    set_key US-2201 KFF-2201  # Sweetwater Creek State Park
    set_key US-2202 KFF-2202  # Tallulah Gorge State Park
    set_key US-2203 KFF-2203  # Tugaloo State Park
    set_key US-2204 KFF-2204  # Unicoi State Park
    set_key US-2205 KFF-2205  # Victoria Bryant State Park
    set_key US-2206 KFF-2206  # Vogel State Park
    set_key US-2207 KFF-2207  # Watson Mill Bridge State Park
    set_key US-2208 KFF-2208  # Akaka Falls State Park
    set_key US-2209 KFF-2209  # Ahupua'a O Kahana State Park
    set_key US-2210 KFF-2210  # Ha'ena State Park
    set_key US-2211 KFF-2211  # Heeia State Park
    set_key US-2212 KFF-2212  # Ka'ena Point State Park
    set_key US-2213 KFF-2213  # Kaumahina Wayside State Park
    set_key US-2214 KFF-2214  # Kekaha Kai State Park
    set_key US-2215 KFF-2215  # Koke`e State Park
    set_key US-2216 KFF-2216  # Makapu'u Point Wayside State Trail
    set_key US-2217 KFF-2217  # Makena State Park
    set_key US-2218 KFF-2218  # Nu'uanu Pali Wayside State Park
    set_key US-2219 KFF-2219  # Palaau State Park
    set_key US-2220 KFF-2220  # Polihale State Park
    set_key US-2221 KFF-2221  # Puaa Kaa Wayside State Park
    set_key US-2222 KFF-2222  # Pu'u 'Ualakaa State Park
    set_key US-2223 KFF-2223  # Waimea Canyon State Park
    set_key US-2224 KFF-2224  # Waianapanapa State Park
    set_key US-2225 KFF-2225  # Wailuku River State Park
    set_key US-2226 KFF-2226  # Wailua River State Park
    set_key US-2227 KFF-2227  # Wailua Valley Wayside State Park
    set_key US-2228 KFF-2228  # Bear Lake State Park
    set_key US-2229 KFF-2229  # Bruneau Dunes State Park
    set_key US-2230 KFF-2230  # Castle Rocks State Park
    set_key US-2231 KFF-2231  # Old Mission State Park
    set_key US-2232 KFF-2232  # Dworshak State Park
    set_key US-2233 KFF-2233  # Eagle Island State Park
    set_key US-2234 KFF-2234  # Farragut State Park
    set_key US-2235 KFF-2235  # Harriman State Park
    set_key US-2236 KFF-2236  # Hells Gate State Park
    set_key US-2237 KFF-2237  # Henrys Lake State Park
    set_key US-2238 KFF-2238  # Heyburn State Park
    set_key US-2239 KFF-2239  # Lake Cascade State Park
    set_key US-2240 KFF-2240  # Lake Walcott State Park
    set_key US-2241 KFF-2241  # Land of the Yankee Fork State Park
    set_key US-2242 KFF-2242  # Lucky Peak State Park
    set_key US-2243 KFF-2243  # Massacre Rocks State Park
    set_key US-2244 KFF-2244  # Mary M. McCroskey State Park
    set_key US-2245 KFF-2245  # Ponderosa State Park
    set_key US-2246 KFF-2246  # Priest Lake State Park
    set_key US-2247 KFF-2247  # Round Lake State Park
    set_key US-2248 KFF-2248  # Thousand Springs State Park
    set_key US-2249 KFF-2249  # Three Island Crossing State Park
    set_key US-2250 KFF-2250  # Winchester Lake State Park
    set_key US-2251 KFF-2251  # Brown County State Park
    set_key US-2252 KFF-2252  # Chain O' Lakes State Park
    set_key US-2253 KFF-2253  # Charlestown State Park
    set_key US-2254 KFF-2254  # Clifty Falls State Park
    set_key US-2255 KFF-2255  # Falls of the Ohio State Park
    set_key US-2256 KFF-2256  # Fort Harrison State Park
    set_key US-2257 KFF-2257  # Harmonie State Park
    set_key US-2258 KFF-2258  # Indiana Dunes State Park
    set_key US-2259 KFF-2259  # Lincoln State Park
    set_key US-2260 KFF-2260  # McCormick's Creek State Park
    set_key US-2261 KFF-2261  # Mounds State Park
    set_key US-2262 KFF-2262  # O'Bannon Woods State Park
    set_key US-2263 KFF-2263  # Ouabache State Park
    set_key US-2264 KFF-2264  # Pokagon State Park
    set_key US-2265 KFF-2265  # Potato Creek State Park
    set_key US-2266 KFF-2266  # Prophetstown State Park
    set_key US-2267 KFF-2267  # Shades State Park
    set_key US-2268 KFF-2268  # Shakamak State Park
    set_key US-2269 KFF-2269  # Spring Mill State Park
    set_key US-2270 KFF-2270  # Summit Lake State Park
    set_key US-2271 KFF-2271  # Tippecanoe River State Park
    set_key US-2272 KFF-2272  # Turkey Run State Park
    set_key US-2273 KFF-2273  # Versailles State Park
    set_key US-2274 KFF-2274  # White River State Park
    set_key US-2275 KFF-2275  # Whitewater Memorial State Park
    set_key US-2276 KFF-2276  # Ambrose A. Call State Park
    set_key US-2277 KFF-2277  # Backbone State Park
    set_key US-2278 KFF-2278  # Banner Lakes at Summerset State Park
    set_key US-2279 KFF-2279  # Beed's Lake State Park
    set_key US-2280 KFF-2280  # Bellevue State Park
    set_key US-2281 KFF-2281  # Big Creek State Park
    set_key US-2282 KFF-2282  # Blackhawk State Park
    set_key US-2283 KFF-2283  # Cedar Rock State Park
    set_key US-2284 KFF-2284  # Clear Lake State Park
    set_key US-2285 KFF-2285  # Dolliver Memorial State Park
    set_key US-2286 KFF-2286  # Elinor Bedell State Park
    set_key US-2287 KFF-2287  # Elk Rock State Park
    set_key US-2288 KFF-2288  # Fort Defiance State Park
    set_key US-2289 KFF-2289  # Geode State Park
    set_key US-2290 KFF-2290  # George Wyth State Park
    set_key US-2291 KFF-2291  # Green Valley State Park
    set_key US-2292 KFF-2292  # Gull Point State Park
    set_key US-2293 KFF-2293  # Honey Creek State Park
    set_key US-2294 KFF-2294  # Lacey-Keosauqua State Park
    set_key US-2295 KFF-2295  # Lake Ahquabi State Park
    set_key US-2296 KFF-2296  # Lake Anita State Park
    set_key US-2297 KFF-2297  # Lake Darling State Park
    set_key US-2298 KFF-2298  # Lake Keomah State Park
    set_key US-2299 KFF-2299  # Lake Macbride State Park
    set_key US-2300 KFF-2300  # Lake Manawa State Park
    set_key US-2301 KFF-2301  # Lake of Three Fires State Park
    set_key US-2302 KFF-2302  # Lake Wapello State Park
    set_key US-2303 KFF-2303  # Ledges State Park
    set_key US-2304 KFF-2304  # Lewis and Clark State Park
    set_key US-2305 KFF-2305  # Maquoketa Caves State Park
    set_key US-2306 KFF-2306  # McIntosh Woods State Park
    set_key US-2307 KFF-2307  # Mini-Wakan State Park
    set_key US-2308 KFF-2308  # Nine Eagles State Park
    set_key US-2309 KFF-2309  # Okamanpeedan State Park
    set_key US-2310 KFF-2310  # Palisades-Kepler State Park
    set_key US-2311 KFF-2311  # Pikes Peak State Park
    set_key US-2312 KFF-2312  # Pikes Point State Park
    set_key US-2313 KFF-2313  # Pilot Knob State Park
    set_key US-2314 KFF-2314  # Pine Lake State Park
    set_key US-2315 KFF-2315  # Prairie Rose State Park
    set_key US-2316 KFF-2316  # Preparation Canyon State Park
    set_key US-2317 KFF-2317  # Red Haw State Park
    set_key US-2318 KFF-2318  # Rice Lake State Park
    set_key US-2319 KFF-2319  # Rock Creek State Park
    set_key US-2320 KFF-2320  # Springbrook State Park
    set_key US-2321 KFF-2321  # Stone State Park
    set_key US-2322 KFF-2322  # Trappers Bay State Park
    set_key US-2323 KFF-2323  # Twin Lakes State Park
    set_key US-2324 KFF-2324  # Union Grove State Park
    set_key US-2325 KFF-2325  # Viking Lake State Park
    set_key US-2326 KFF-2326  # Walnut Woods State Park
    set_key US-2327 KFF-2327  # Wapsipinicon State Park
    set_key US-2328 KFF-2328  # Waubonsie State Park
    set_key US-2329 KFF-2329  # Wild Cat Den State Park
    set_key US-2330 KFF-2330  # Cedar Bluff State Park
    set_key US-2331 KFF-2331  # Cheney State Park
    set_key US-2332 KFF-2332  # Clinton State Park
    set_key US-2333 KFF-2333  # Crawford State Park
    set_key US-2334 KFF-2334  # Cross Timbers State Park
    set_key US-2335 KFF-2335  # Eisenhower State Park
    set_key US-2336 KFF-2336  # El Dorado State Park
    set_key US-2337 KFF-2337  # Elk City State Park
    set_key US-2338 KFF-2338  # Fall River State Park
    set_key US-2339 KFF-2339  # Glen Elder State Park
    set_key US-2340 KFF-2340  # Hillsdale State Park
    set_key US-2341 KFF-2341  # Kaw River State Park
    set_key US-2342 KFF-2342  # Kanopolis Lake State Park
    set_key US-2343 KFF-2343  # Lovewell State Park
    set_key US-2344 KFF-2344  # Meade State Park
    set_key US-2345 KFF-2345  # Milford State Park
    set_key US-2346 KFF-2346  # Mushroom Rock State Park
    set_key US-2347 KFF-2347  # Perry State Park
    set_key US-2348 KFF-2348  # Pomona State Park
    set_key US-2349 KFF-2349  # Prairie Dog State Park
    set_key US-2350 KFF-2350  # Prairie Spirit State Park
    set_key US-2351 KFF-2351  # Sandhills State Park
    set_key US-2352 KFF-2352  # Lake Scott State Park
    set_key US-2353 KFF-2353  # Tuttle Creek State Park
    set_key US-2354 KFF-2354  # Webster State Park
    set_key US-2355 KFF-2355  # Wilson State Park
    set_key US-2356 KFF-2356  # Bayou Segnette State Park
    set_key US-2357 KFF-2357  # Bogue Chitto State Park
    set_key US-2358 KFF-2358  # Chemin-A-Haut State Park
    set_key US-2359 KFF-2359  # Chicot State Park
    set_key US-2360 KFF-2360  # Cypremort Point State Park
    set_key US-2361 KFF-2361  # Fairview-Riverside State Park
    set_key US-2362 KFF-2362  # Fontainebleau State Park
    set_key US-2363 KFF-2363  # Grand Isle State Park
    set_key US-2364 KFF-6848  # Machicomoco State Park
    set_key US-2365 KFF-2365  # Jimmie Davis State Park
    set_key US-2366 KFF-2366  # Lake Bistineau State Park
    set_key US-2367 KFF-2367  # Lake Bruin State Park
    set_key US-2368 KFF-2368  # Lake Claiborne State Park
    set_key US-2369 KFF-2369  # Lake D'Arbonne State Park
    set_key US-2370 KFF-2370  # Lake Fausse Pointe State Park
    set_key US-2371 KFF-2371  # North Toledo Bend State Park
    set_key US-2372 KFF-2372  # Palmetto Island State Park
    set_key US-2373 KFF-2373  # Poverty Point Reservoir State Park
    set_key US-2374 KFF-2374  # Saint Bernard State Park
    set_key US-2375 KFF-2375  # Sam Houston Jones State Park
    set_key US-2376 KFF-2376  # South Toledo Bend State Park
    set_key US-2377 KFF-2377  # Tickfaw State Park
    set_key US-2378 KFF-2378  # Allagash Wilderness Waterway State Park
    set_key US-2379 KFF-2379  # Androscoggin Riverlands State Park
    set_key US-2380 KFF-2380  # Aroostook State Park
    set_key US-2381 KFF-2381  # Baxter State Park
    set_key US-2382 KFF-2382  # Birch Point Beach State Park
    set_key US-2383 KFF-2383  # Bradbury Mountain State Park
    set_key US-2384 KFF-2384  # Camden Hills State Park
    set_key US-2385 KFF-2385  # Cobscook Bay State Park
    set_key US-2386 KFF-2386  # Crescent Beach State Park
    set_key US-2387 KFF-2387  # Damariscotta Lake State Park
    set_key US-2388 KFF-2388  # Ferry Beach State Park
    set_key US-2389 KFF-2389  # Fort Point State Park
    set_key US-2390 KFF-2390  # Grafton Notch State Park
    set_key US-2391 KFF-2391  # Holbrook Island Sanctuary State Park
    set_key US-2392 KFF-2392  # Lake St. George State Park
    set_key US-2393 KFF-2393  # Lamoine State Park
    set_key US-2394 KFF-2394  # Lily Bay State Park
    set_key US-2395 KFF-2395  # Mackworth Island State Park
    set_key US-2396 KFF-2396  # Moose Point State Park
    set_key US-2397 KFF-2397  # Mount Blue State Park
    set_key US-2398 KFF-2398  # Mount Kineo State Park
    set_key US-2399 KFF-2399  # Owls Head State Park
    set_key US-2400 KFF-2400  # Peacock Beach State Park
    set_key US-2401 KFF-2401  # Peaks-Kenny State Park
    set_key US-2402 KFF-2402  # Penobscot River Corridor - Katahdin Woods and Waters State Park
    set_key US-2403 KFF-2403  # Popham Beach State Park
    set_key US-2404 KFF-2404  # Quoddy Head State Park
    set_key US-2405 KFF-2405  # Range Ponds State Park
    set_key US-2406 KFF-2406  # Rangeley Lake State Park
    set_key US-2407 KFF-2407  # Reid State Park
    set_key US-2408 KFF-2408  # Roque Bluffs State Park
    set_key US-2409 KFF-2409  # Sebago Lake State Park
    set_key US-2410 KFF-2410  # Shackford Head State Park
    set_key US-2411 KFF-2411  # Swan Lake State Park
    set_key US-2412 KFF-2412  # Two Lights State Park
    set_key US-2413 KFF-2413  # Vaughan Woods State Park
    set_key US-2414 KFF-2414  # Warren Island State Park
    set_key US-2415 KFF-2415  # Wolfe's Neck Woods State Park
    set_key US-2416 KFF-2416  # Ames Nowell State Park
    set_key US-2417 KFF-2417  # Ashland State Park
    set_key US-2418 KFF-2418  # Bash Bish Falls State Park
    set_key US-2419 KFF-2419  # Blackstone River and Canal Heritage State Park
    set_key US-2420 KFF-2420  # Borderland State Park
    set_key US-2421 KFF-2421  # Boston Harbor Islands National Recreation Area
    set_key US-2422 KFF-2422  # Bradley Palmer State Park
    set_key US-2423 KFF-2423  # C.M. Gardner State Park
    set_key US-2424 KFF-2424  # Callahan State Park
    set_key US-2425 KFF-2425  # Chicopee Memorial State Park
    set_key US-2426 KFF-2426  # Clarksburg State Park
    set_key US-2427 KFF-2427  # Cochituate State Park
    set_key US-2428 KFF-2428  # Connecticut River Greenway State Park
    set_key US-2429 KFF-2429  # Demarest Lloyd State Park
    set_key US-2430 KFF-2430  # Dighton Rock State Park
    set_key US-2431 KFF-2431  # Dunn State Park
    set_key US-2432 KFF-2432  # Ellisville Harbor State Park
    set_key US-2433 KFF-2433  # Fall River Heritage State Park
    set_key US-2435 KFF-2435  # Great Brook Farm State Park
    set_key US-2436 KFF-2436  # Greycourt State Park
    set_key US-2437 KFF-2437  # Halibut Point State Park
    set_key US-2438 KFF-2438  # Hampton Ponds State Park
    set_key US-2439 KFF-2439  # Holyoke Heritage State Park
    set_key US-2440 KFF-2440  # Hopkinton State Park
    set_key US-2442 KFF-2442  # Lake Wyola State Park
    set_key US-2443 KFF-2443  # Lawrence Heritage State Park
    set_key US-2444 KFF-2444  # Lowell Heritage State Park
    set_key US-2445 KFF-2445  # Lynn Heritage State Park
    set_key US-2446 KFF-2446  # Massasoit State Park
    set_key US-2447 KFF-2447  # Maudslay State Park
    set_key US-2448 KFF-2448  # Moore State Park
    set_key US-2449 KFF-2449  # Mount Holyoke Range State Park
    set_key US-2450 KFF-2450  # Natural Bridge State Park
    set_key US-2451 KFF-2451  # Nickerson State Park
    set_key US-2452 KFF-2452  # Pearl Hill State Park
    set_key US-2453 KFF-2453  # Pilgrim Memorial State Park
    set_key US-2454 KFF-2454  # Quinsigamond State Park
    set_key US-2455 KFF-2455  # Robinson State Park
    set_key US-2456 KFF-2456  # Roxbury Heritage State Park
    set_key US-2457 KFF-2457  # Rutland State Park
    set_key US-2458 KFF-2458  # J. A. Skinner State Park
    set_key US-2459 KFF-2459  # Wahconah Falls State Park
    set_key US-2460 KFF-2460  # Watson Pond State Park
    set_key US-2461 KFF-2461  # Webb Memorial State Park
    set_key US-2462 KFF-2462  # Wells State Park
    set_key US-2463 KFF-2463  # Western Gateway Heritage State Park
    set_key US-2464 KFF-2464  # Whitehall State Park
    set_key US-2465 KFF-2465  # Wompatuck State Park
    set_key US-2466 KFF-2466  # Afton State Park
    set_key US-2467 KFF-2467  # Banning State Park
    set_key US-2468 KFF-2468  # Bear Head Lake State Park
    set_key US-2469 KFF-2469  # Beaver Creek Valley State Park
    set_key US-2470 KFF-2470  # Big Stone Lake State Park
    set_key US-2471 KFF-2471  # Blue Mounds State Park
    set_key US-2472 KFF-2472  # Buffalo River State Park
    set_key US-2473 KFF-2473  # Camden State Park
    set_key US-2474 KFF-2474  # Carley State Park
    set_key US-2475 KFF-2475  # Cascade River State Park
    set_key US-2476 KFF-2476  # Charles A. Lindbergh State Park
    set_key US-2477 KFF-2477  # Crow Wing State Park
    set_key US-2478 KFF-2478  # Father Hennepin State Park
    set_key US-2479 KFF-2479  # Flandrau State Park
    set_key US-2480 KFF-2480  # Forestville/Mystery Cave State Park
    set_key US-2481 KFF-2481  # Fort Ridgely State Park
    set_key US-2482 KFF-2482  # Fort Snelling State Park
    set_key US-2483 KFF-2483  # Franz Jevne State Park
    set_key US-2484 KFF-2484  # Frontenac State Park
    set_key US-2485 KFF-2485  # George Crosby Manitou State Park
    set_key US-2486 KFF-2486  # Glacial Lakes State Park
    set_key US-2487 KFF-2487  # Glendalough State Park
    set_key US-2488 KFF-2488  # Gooseberry Falls State Park
    set_key US-2489 KFF-2489  # Grand Portage State Park
    set_key US-2490 KFF-2490  # Great River Bluffs State Park
    set_key US-2491 KFF-2491  # Hayes Lake State Park
    set_key US-2492 KFF-2492  # Hill Annex Mine State Park
    set_key US-2493 KFF-2493  # Interstate State Park
    set_key US-2494 KFF-2494  # Itasca State Park
    set_key US-2495 KFF-2495  # Jay Cooke State Park
    set_key US-2496 KFF-2496  # John A. Latsch State Park
    set_key US-2497 KFF-2497  # Judge C.R. Magney State Park
    set_key US-2498 KFF-2498  # Kilen Woods State Park
    set_key US-2499 KFF-2499  # Lac Qui Parle State Park
    set_key US-2500 KFF-2500  # Lake Bemidji State Park
    set_key US-2501 KFF-2501  # Lake Bronson State Park
    set_key US-2502 KFF-2502  # Lake Carlos State Park
    set_key US-2503 KFF-2503  # Lake Louise State Park
    set_key US-2504 KFF-2504  # Lake Maria State Park
    set_key US-2505 KFF-2505  # Lake Shetek State Park
    set_key US-2506 KFF-2506  # Lake Vermilion State Park
    set_key US-2507 KFF-2507  # Maplewood State Park
    set_key US-2508 KFF-2508  # McCarthy Beach State Park
    set_key US-2509 KFF-2509  # Mille Lacs Kathio State Park
    set_key US-2510 KFF-2510  # Minneopa State Park
    set_key US-2511 KFF-2511  # Monson Lake State Park
    set_key US-2512 KFF-2512  # Moose Lake State Park
    set_key US-2513 KFF-2513  # Myre-Big Island State Park
    set_key US-2514 KFF-2514  # Nerstrand Big Woods State Park
    set_key US-2515 KFF-2515  # Old Mill State Park
    set_key US-2516 KFF-2516  # Rice Lake State Park
    set_key US-2517 KFF-2517  # St. Croix State Park
    set_key US-2518 KFF-2518  # Sakatah Lake State Park
    set_key US-2519 KFF-2519  # Savanna Portage State Park
    set_key US-2520 KFF-2520  # Scenic State Park
    set_key US-2521 KFF-2521  # Schoolcraft State Park
    set_key US-2522 KFF-2522  # Sibley State Park
    set_key US-2523 KFF-2523  # Split Rock Creek State Park
    set_key US-2524 KFF-2524  # Split Rock Lighthouse State Park
    set_key US-2525 KFF-2525  # Temperance River State Park
    set_key US-2526 KFF-2526  # Tettegouche State Park
    set_key US-2527 KFF-2527  # Upper Sioux Agency State Park
    set_key US-2528 KFF-2528  # Whitewater State Park
    set_key US-2529 KFF-2529  # Wild River State Park
    set_key US-2530 KFF-2530  # William O'Brien State Park
    set_key US-2531 KFF-2531  # Zippel Bay State Park
    set_key US-2532 KFF-2532  # Buccaneer State Park
    set_key US-2533 KFF-2533  # Clarkco State Park
    set_key US-2534 KFF-2534  # Florewood State Park
    set_key US-2535 KFF-2535  # George P Cossar State Park
    set_key US-2536 KFF-2536  # Golden Memorial State Park
    set_key US-2537 KFF-2537  # Great River Road State Park
    set_key US-2538 KFF-2538  # Holmes County State Park
    set_key US-2539 KFF-2539  # Hugh White State Park
    set_key US-2540 KFF-2540  # John W. Kyle State Park
    set_key US-2541 KFF-2541  # J P Coleman State Park
    set_key US-2542 KFF-2542  # Lake Lincoln State Park
    set_key US-2543 KFF-2543  # Lake Lowndes State Park
    set_key US-2544 KFF-2544  # Lefleur's Bluff State Park
    set_key US-2545 KFF-2545  # Legion State Park
    set_key US-2546 KFF-2546  # Leroy Percy State Park
    set_key US-2547 KFF-2547  # Natchez State Park
    set_key US-2548 KFF-2548  # Paul B. Johnson State Park
    set_key US-2549 KFF-2549  # Percy E Quin State Park
    set_key US-2550 KFF-2550  # Roosevelt State Park
    set_key US-2551 KFF-2551  # Shepard State Park
    set_key US-2552 KFF-2552  # Tishomingo State Park
    set_key US-2553 KFF-2553  # Tombigbee State Park
    set_key US-2554 KFF-2554  # Trace State Park
    set_key US-2555 KFF-2555  # Wall Doxey State Park
    set_key US-2556 KFF-2556  # Ackley Lake State Park
    set_key US-2557 KFF-2557  # Anaconda Smelter Stack State Park
    set_key US-2558 KFF-2558  # Bannack State Park
    set_key US-2559 KFF-2559  # Beaverhead Rock State Park
    set_key US-2560 KFF-2560  # Beavertail Hill State Park
    set_key US-2561 KFF-2561  # Big Arm State Park
    set_key US-2562 KFF-2562  # Black Sandy State Park
    set_key US-2563 KFF-2563  # Brush Lake State Park
    set_key US-2564 KFF-2564  # Chief Plenty Coups State Park
    set_key US-2565 KFF-2565  # Clarks Lookout State Park
    set_key US-2566 KFF-2566  # Cooney Reservoir State Park
    set_key US-2567 KFF-2567  # Council Grove State Park
    set_key US-2568 KFF-2568  # Elkhorn State Park
    set_key US-2569 KFF-2569  # Finley Point State Park
    set_key US-2570 KFF-2570  # First Peoples Buffalo Jump State Park
    set_key US-2571 KFF-2571  # Fish Creek State Park
    set_key US-2572 KFF-2572  # Fort Owen State Park
    set_key US-2573 KFF-2573  # Frenchtown Pond State Park
    set_key US-2574 KFF-2574  # Giant Springs State Park
    set_key US-2576 KFF-2576  # Grey Cliff Prairie Dog State Park
    set_key US-2577 KFF-2577  # Hell Creek State Park
    set_key US-2578 KFF-2578  # Lake Elmo State Park
    set_key US-2579 KFF-2579  # Lake Mary Ronan State Park
    set_key US-2580 KFF-2580  # Les Mason State Park
    set_key US-2581 KFF-2581  # Lewis and Clark Caverns State Park
    set_key US-2582 KFF-2582  # Logan State Park
    set_key US-2583 KFF-2583  # Lone Pine State Park
    set_key US-2584 KFF-2584  # Lost Creek State Park
    set_key US-2585 KFF-2585  # Madison Buffalo Jump State Park
    set_key US-2586 KFF-2586  # Makoshika State Park
    set_key US-2587 KFF-2587  # Marias River State Park
    set_key US-2588 KFF-2588  # Medicine Rocks State Park
    set_key US-2589 KFF-2589  # Missouri Headwaters State Park
    set_key US-2590 KFF-2590  # Painted Rocks State Park
    set_key US-2591 KFF-2591  # Pictograph Cave State Park
    set_key US-2592 KFF-2592  # Pirogue Island State Park
    set_key US-2593 KFF-2593  # Placid Lake State Park
    set_key US-2594 KFF-2594  # Rosebud Battlefield State Park
    set_key US-2595 KFF-2595  # Salmon Lake State Park
    set_key US-2596 KFF-2596  # Sluice Boxes State Park
    set_key US-2597 KFF-2597  # Smith River State Park
    set_key US-2598 KFF-2598  # Spring Meadow Lake State Park
    set_key US-2599 KFF-2599  # Thompson Falls State Park
    set_key US-2600 KFF-2600  # Tongue River Reservoir State Park
    set_key US-2601 KFF-2601  # Tower Rock State Park
    set_key US-2602 KFF-2602  # Travelers' Rest State Park
    set_key US-2603 KFF-2603  # Wayfarers State Park
    set_key US-2604 KFF-2604  # West Shore State Park
    set_key US-2605 KFF-2605  # Whitefish Lake State Park
    set_key US-2606 KFF-2606  # Wild Horse Island State Park
    set_key US-2607 KFF-2607  # Yellow Bay State Park
    set_key US-2608 KFF-2608  # Ashfall Fossil Bedsal State Park
    set_key US-2609 KFF-2609  # Ash Hollow State Park
    set_key US-2610 KFF-2610  # Arbor Lodge State Historical Park
    set_key US-2611 KFF-2611  # Bowring Ranch State Historical Park
    set_key US-2612 KFF-2612  # Buffalo Bill Ranch State Historical Park
    set_key US-2613 KFF-2613  # Chadron State Park
    set_key US-2614 KFF-2614  # Eugene T. Mahoney State Park
    set_key US-2615 KFF-2615  # Fort Atkinson State Historical Park
    set_key US-2616 KFF-2616  # Fort Hartsuff State Historical Park
    set_key US-2617 KFF-2617  # Fort Kearny State Historical Park
    set_key US-2618 KFF-2618  # Fort Robinson State Park
    set_key US-2619 KFF-2619  # Indian Cave State Park
    set_key US-2620 KFF-2620  # Niobrara State Park
    set_key US-2621 KFF-2621  # Platte River State Park
    set_key US-2622 KFF-2622  # Ponca State Park
    set_key US-2623 KFF-2623  # Rock Creek Station State Historical Park
    set_key US-2624 KFF-2624  # Smith Falls State Park
    set_key US-2625 KFF-2625  # Beaver Dam State Park
    set_key US-2626 KFF-2626  # Berlin-Ichthyosaur State Park
    set_key US-2627 KFF-2627  # Cathedral Gorge State Park
    set_key US-2628 KFF-2628  # Cave Lake State Park
    set_key US-2629 KFF-2629  # Dayton State Park
    set_key US-2630 KFF-2630  # Echo Canyon State Park
    set_key US-2631 KFF-2631  # Fort Churchill State Park
    set_key US-2632 KFF-2632  # Kershaw-Ryan State Park
    set_key US-2633 KFF-2633  # Lake Tahoe State Park
    set_key US-2634 KFF-2634  # Mormon Station State Park
    set_key US-2635 KFF-2635  # Spring Mountain Ranch State Park
    set_key US-2636 KFF-2636  # Spring Valley State Park
    set_key US-2637 KFF-2637  # Valley of Fire State Park
    set_key US-2638 KFF-2638  # Van Sickle Bi State Park
    set_key US-2639 KFF-2639  # Ward Charcoal Ovens State Park
    set_key US-2640 KFF-2640  # Washoe Lake State Park
    set_key US-2641 KFF-2641  # Ahern State Park
    set_key US-2642 KFF-2642  # Androscoggin Wayside State Park
    set_key US-2643 KFF-2643  # Bear Brook State Park
    set_key US-2644 KFF-2644  # Cardigan Mountain State Park
    set_key US-2645 KFF-2645  # Clough State Park
    set_key US-2646 KFF-2646  # Coleman State Park
    set_key US-2647 KFF-2647  # Crawford Notch State Park
    set_key US-2648 KFF-2648  # Dixville Notch State Park
    set_key US-2649 KFF-2649  # Echo Lake State Park
    set_key US-2650 KFF-2650  # Eisenhower Memorial Wayside State Park
    set_key US-2651 KFF-2651  # Ellacoya State Park
    set_key US-2652 KFF-2652  # Forest Lake State Park
    set_key US-2653 KFF-2653  # Franconia Notch State Park
    set_key US-2654 KFF-2654  # Gardner Memorial Wayside State Park
    set_key US-2655 KFF-2655  # Greenfield State Park
    set_key US-2656 KFF-2656  # Hampton Beach State Park
    set_key US-2657 KFF-2657  # Jericho Mountain State Park
    set_key US-2658 KFF-2658  # Kingston State Park
    set_key US-2659 KFF-2659  # Lake Francis State Park
    set_key US-2660 KFF-2660  # Lake Tarleton State Park
    set_key US-2661 KFF-2661  # Milan Hill State Park
    set_key US-2662 KFF-2662  # Miller State Park
    set_key US-2663 KFF-2663  # Mollidgewock State Park
    set_key US-2664 KFF-2664  # Monadnock State Park
    set_key US-2665 KFF-2665  # Moose Brook State Park
    set_key US-2666 KFF-2666  # Mount Sunapee State Park
    set_key US-2667 KFF-2667  # Mount Washington State Park
    set_key US-2668 KFF-2668  # Nansen Wayside State Park
    set_key US-2669 KFF-2669  # North Hampton State Park
    set_key US-2670 KFF-2670  # Northwood Meadows State Park
    set_key US-2671 KFF-2671  # Odiorne Point State Park
    set_key US-2672 KFF-2672  # Pawtuckaway State Park
    set_key US-2673 KFF-2673  # Pillsbury State Park
    set_key US-2674 KFF-2674  # Pisgah State Park
    set_key US-2675 KFF-2675  # Rhododendron State Park
    set_key US-2676 KFF-2676  # Rollins State Park
    set_key US-2677 KFF-2677  # Rye Harbor State Park
    set_key US-2678 KFF-2678  # Silver Lake State Park
    set_key US-2679 KFF-2679  # Umbagog Lake State Park
    set_key US-2680 KFF-2680  # Wadleigh State Park
    set_key US-2681 KFF-2681  # Weeks State Park
    set_key US-2682 KFF-2682  # Wellington State Park
    set_key US-2683 KFF-2683  # Wentworth State Park
    set_key US-2684 KFF-2684  # White Lake State Park
    set_key US-2685 KFF-2685  # Winslow State Park
    set_key US-2686 KFF-2686  # Bluewater State Park
    set_key US-2687 KFF-2687  # Bottomless Lakes State Park
    set_key US-2688 KFF-2688  # Brantley Lake State Park
    set_key US-2689 KFF-2689  # Caballo Lake State Park
    set_key US-2690 KFF-2690  # Cerrillos Hills State Park
    set_key US-2691 KFF-2691  # Cimarron Canyon State Park
    set_key US-2692 KFF-2692  # City of Rock State Park
    set_key US-2693 KFF-2693  # Clayton Lake State Park
    set_key US-2694 KFF-2694  # Conchas Lake State Park
    set_key US-2695 KFF-2695  # Coyote Creek State Park
    set_key US-2696 KFF-2696  # Eagle Nest Lake State Park
    set_key US-2697 KFF-2697  # Elephant Butte Lake State Park
    set_key US-2698 KFF-2698  # El Vado Lake State Park
    set_key US-2699 KFF-2699  # Fenton Lake State Park
    set_key US-2700 KFF-2700  # Heron Lake State Park
    set_key US-2701 KFF-2701  # Hyde Memorial State Park
    set_key US-2702 KFF-2702  # Leasburg Dam State Park
    set_key US-2703 KFF-2703  # Living Desert State Park
    set_key US-2704 KFF-2704  # Manzano Mountains State Park
    set_key US-2705 KFF-2705  # Mesilla Valley Bosque State Park
    set_key US-2706 KFF-2706  # Morphy Lake State Park
    set_key US-2707 KFF-2707  # Navajo Lake State Park
    set_key US-2708 KFF-2708  # Oasis State Park
    set_key US-2709 KFF-2709  # Oliver Lee Memorial State Park
    set_key US-2710 KFF-2710  # Pancho Villa State Park
    set_key US-2711 KFF-2711  # Percha Dam State Park
    set_key US-2712 KFF-2712  # Rio Grande Nature Center State Park
    set_key US-2713 KFF-2713  # Rock Hound State Park
    set_key US-2714 KFF-2714  # Santa Rosa Lake State Park
    set_key US-2715 KFF-2715  # Storrie Lake State Park
    set_key US-2716 KFF-2716  # Sugarite Canyon State Park
    set_key US-2717 KFF-2717  # Sumner Lake State Park
    set_key US-2718 KFF-2718  # Ute Lake State Park
    set_key US-2719 KFF-2719  # Angel Fire Vietnam Veterans Memorial State Park
    set_key US-2720 KFF-2720  # Villanueva State Park
    set_key US-2721 KFF-2721  # Bay Tree Lake State Park
    set_key US-2722 KFF-2722  # Carolina Beach State Park
    set_key US-2723 KFF-2723  # Carvers Creek State Park
    set_key US-2724 KFF-2724  # Chimney Rock State Park
    set_key US-2725 KFF-2725  # Cliffs of the Neuse State Park
    set_key US-2726 KFF-2726  # Crowders Mountain State Park
    set_key US-2727 KFF-2727  # Dismal Swamp State Park
    set_key US-2728 KFF-2728  # Elk Knob State Park
    set_key US-2729 KFF-2729  # Eno River State Park
    set_key US-2730 KFF-2730  # Fort Macon State Park
    set_key US-2731 KFF-2731  # Goose Creek State Park
    set_key US-2732 KFF-2732  # Gorges State Park
    set_key US-2733 KFF-2733  # Grandfather Mountain State Park
    set_key US-2734 KFF-2734  # Hammocks Beach State Park
    set_key US-2735 KFF-2735  # Hanging Rock State Park
    set_key US-2736 KFF-2736  # Haw River at Summit Center State Park
    set_key US-2737 KFF-2737  # Jockey's Ridge State Park
    set_key US-2738 KFF-2738  # Jones Lake State Park
    set_key US-2739 KFF-2739  # Lake James State Park
    set_key US-2740 KFF-2740  # Lake Norman State Park
    set_key US-2741 KFF-2741  # Lake Waccamaw State Park
    set_key US-2742 KFF-2742  # Lumber River State Park
    set_key US-2743 KFF-2743  # Mayo River State Park
    set_key US-2744 KFF-2744  # Medoc Mountain State Park
    set_key US-2745 KFF-2745  # Merchants Millpond State Park
    set_key US-2746 KFF-2746  # Morrow Mountain State Park
    set_key US-2747 KFF-2747  # Mount Mitchell State Park
    set_key US-2748 KFF-2748  # New River State Park
    set_key US-2749 KFF-2749  # Pettigrew State Park
    set_key US-2750 KFF-2750  # Pilot Mountain State Park
    set_key US-2751 KFF-2751  # Raven Rock State Park
    set_key US-2752 KFF-2752  # Singletary Lake State Park
    set_key US-2753 KFF-2753  # South Mountains State Park
    set_key US-2754 KFF-2754  # Stone Mountain State Park
    set_key US-2755 KFF-2755  # William B. Umstead State Park
    set_key US-2756 KFF-2756  # Beaver Lake State Park
    set_key US-2757 KFF-2757  # Cross Ranch State Park
    set_key US-2758 KFF-2758  # Fort Abraham Lincoln State Park
    set_key US-2759 KFF-2759  # Fort Ransom State Park
    set_key US-2760 KFF-2760  # Fort Stevenson State Park
    set_key US-2761 KFF-2761  # Grahams Island State Park
    set_key US-2762 KFF-2762  # Icelandic State Park
    set_key US-2763 KFF-2763  # Lake Metigoshe State Park
    set_key US-2764 KFF-2764  # Lake Sakakawea State Park
    set_key US-2765 KFF-2765  # Lewis and Clark State Park
    set_key US-2766 KFF-2766  # Little Missouri State Park
    set_key US-2767 KFF-2767  # Sully Creek State Park
    set_key US-2768 KFF-2768  # Turtle River State Park
    set_key US-2769 KFF-2769  # Alabaster Caverns State Park
    set_key US-2770 KFF-2770  # Arrowhead State Park
    set_key US-2771 KFF-2771  # Beavers Bend Resort State Park
    set_key US-2772 KFF-2772  # Bernice State Park
    set_key US-2773 KFF-2773  # Black Mesa State Park
    set_key US-2774 KFF-2774  # Boiling Springs State Park
    set_key US-2775 KFF-2775  # Cherokee Landing State Park
    set_key US-2776 KFF-4800  # Cherokee State Park
    set_key US-2777 KFF-2777  # Clayton Lake State Park
    set_key US-2778 KFF-2778  # Little Blue Area at Grand Lake State Park (Disney)
    set_key US-2779 KFF-2779  # Fort Cobb State Park
    set_key US-2780 KFF-2780  # Foss State Park
    set_key US-2781 KFF-2781  # Gloss Mountain State Park
    set_key US-2782 KFF-2782  # Great Plains State Park
    set_key US-2783 KFF-2783  # Great Salt Plains State Park
    set_key US-2784 KFF-2784  # Greenleaf State Park
    set_key US-2785 KFF-2785  # Hochatown State Park
    set_key US-2786 KFF-2786  # Honey Creek State Park
    set_key US-2787 KFF-2787  # Hugo Lake State Park
    set_key US-2788 KFF-2788  # Keystone State Park
    set_key US-2789 KFF-2789  # Lake Eufaula State Park
    set_key US-2790 KFF-2790  # Lake Murray State Park
    set_key US-2791 KFF-2791  # Lake Texoma State Park
    set_key US-2792 KFF-2792  # Lake Thunderbird State Park
    set_key US-2793 KFF-2793  # Lake Wister State Park
    set_key US-2794 KFF-2794  # Little Sahara State Park
    set_key US-2795 KFF-2795  # McGee Creek State Park
    set_key US-2796 KFF-2796  # Natural Falls State Park
    set_key US-2797 KFF-2797  # Osage Hills State Park
    set_key US-2798 KFF-2798  # Raymond Gary State Park
    set_key US-2799 KFF-2799  # Red Rock Canyon State Park
    set_key US-2800 KFF-2800  # Robbers Cave State Park
    set_key US-2801 KFF-2801  # Roman Nose State Park
    set_key US-2802 KFF-2802  # Sequoyah Bay State Park
    set_key US-2803 KFF-2803  # Sequoyah State Park
    set_key US-2804 KFF-2804  # Snowdale Area at Grand Lake State Park
    set_key US-2805 KFF-4833  # Spavinaw State Park
    set_key US-2806 KFF-2806  # Talimena State Park
    set_key US-2807 KFF-2807  # Tenkiller State Park
    set_key US-2808 KFF-2808  # Twin Bridges State Park
    set_key US-2809 KFF-2809  # Ainsworth State Park
    set_key US-2810 KFF-2810  # Alderwood Wayside State Park
    set_key US-2811 KFF-2811  # Alfred A Loeb State Park
    set_key US-2812 KFF-2812  # Bates State Park
    set_key US-2813 KFF-2813  # Beverly Beach State Park
    set_key US-2814 KFF-2814  # Bob Straub State Park
    set_key US-2815 KFF-2815  # Brian Booth State Park
    set_key US-2816 KFF-2816  # Bullards Beach State Park
    set_key US-2817 KFF-2817  # Cape Arago State Park
    set_key US-2818 KFF-2818  # Cape Blanco State Park
    set_key US-2819 KFF-2819  # Cape Lookout State Park
    set_key US-2820 KFF-2820  # Carl G. Washburne Memorial State Park
    set_key US-2821 KFF-2821  # Cascadia State Park
    set_key US-2822 KFF-2822  # Catherine Creek State Park
    set_key US-2823 KFF-2823  # Chandler Wayside State Park
    set_key US-2824 KFF-2824  # Collier Memorial State Park
    set_key US-2825 KFF-2825  # Cottonwood Canyon State Park
    set_key US-2826 KFF-2826  # Ecola State Park
    set_key US-2827 KFF-2827  # Elijah Bristow State Park
    set_key US-2828 KFF-2828  # Ellmaker State Wayside State Park
    set_key US-2829 KFF-2829  # Fort Stevens State Park
    set_key US-2830 KFF-2830  # Guy W. Talbot State Park
    set_key US-2831 KFF-2831  # Harris Beach State Park
    set_key US-2832 KFF-2832  # Hat Rock State Park
    set_key US-2833 KFF-2833  # Hilgard Junction State Park
    set_key US-2834 KFF-2834  # Hoffman Memorial State Park
    set_key US-2835 KFF-2835  # Humbug Mountain State Park
    set_key US-2836 KFF-2836  # Illinois River Forks State Park
    set_key US-2837 KFF-2837  # Jessie M. Honeyman Memorial State Park
    set_key US-2838 KFF-2838  # L.L. Stub Stewart State Park
    set_key US-2839 KFF-2839  # LaPine State Park
    set_key US-2840 KFF-2840  # Lake Owyhee State Park
    set_key US-2841 KFF-2841  # Mayer State Park
    set_key US-2842 KFF-2842  # Memaloose State Park
    set_key US-2843 KFF-2843  # Milo McIver State Park
    set_key US-2844 KFF-2844  # Molalla River State Park
    set_key US-2845 KFF-2845  # Nehalem Bay State Park
    set_key US-2846 KFF-2846  # Oregon State Capitol State Park
    set_key US-2847 KFF-2847  # Oswald West State Park
    set_key US-2848 KFF-2848  # Port Orford Heads State Park
    set_key US-2849 KFF-2849  # Prineville Reservoir State Park
    set_key US-2850 KFF-2850  # Rooster Rock State Park
    set_key US-2851 KFF-2851  # Shore Acres State Park
    set_key US-2852 KFF-2852  # Silver Falls State Park
    set_key US-2853 KFF-2853  # Smith Rock State Park
    set_key US-2854 KFF-2854  # South Beach State Park
    set_key US-2855 KFF-2855  # Starvation Creek State Park
    set_key US-2856 KFF-2856  # Sunset Bay State Park
    set_key US-2857 KFF-2857  # The Cove Palisades State Park
    set_key US-2858 KFF-2858  # Tub Springs State Park
    set_key US-2859 KFF-2859  # Tumalo State Park
    set_key US-2860 KFF-2860  # Umpqua Lighthouse State Park
    set_key US-2861 KFF-2861  # Valley of the Rogue State Park
    set_key US-2862 KFF-2862  # Viento State Park
    set_key US-2863 KFF-2863  # Wallowa Lake State Park
    set_key US-2864 KFF-2864  # Wallowa Lake Hwy Scenic Corridor State Park
    set_key US-2865 KFF-2865  # White River Falls State Park
    set_key US-2866 KFF-2866  # Willamette Mission State Park
    set_key US-2867 KFF-2867  # William M. Tugman State Park
    set_key US-2868 KFF-2868  # Beavertail State Park
    set_key US-2869 KFF-2869  # Blackstone River State Park
    set_key US-2870 KFF-2870  # Brenton Point State Park
    set_key US-2871 KFF-2871  # Burlingame State Park
    set_key US-2872 KFF-2872  # Colt State Park
    set_key US-2873 KFF-2873  # Fishermen's Memorial State Park
    set_key US-2874 KFF-2874  # Fort Adams State Park
    set_key US-2875 KFF-2875  # Fort Wetherill State Park
    set_key US-2876 KFF-2876  # Goddard Memorial State Park
    set_key US-2877 KFF-2877  # Haines Memorial State Park
    set_key US-2878 KFF-2878  # Lincoln Woods State Park
    set_key US-2879 KFF-2879  # Rocky Point State Park
    set_key US-2880 KFF-2880  # Snake Den State Park
    set_key US-2881 KFF-2881  # World War II Veterans Memorial State Park
    set_key US-2882 KFF-2882  # Aiken State Park
    set_key US-2883 KFF-2883  # Andrew Jackson State Park
    set_key US-2884 KFF-2884  # Baker Creek State Park
    set_key US-2885 KFF-2885  # Barnwell State Park
    set_key US-2886 KFF-2886  # Caesar's Head State Park
    set_key US-2887 KFF-2887  # Calhoun Falls State Park
    set_key US-2888 KFF-2888  # Cheraw State Park
    set_key US-2889 KFF-2889  # Chester State Park
    set_key US-2890 KFF-2890  # Colleton State Park
    set_key US-2891 KFF-2891  # Croft State Park
    set_key US-2892 KFF-2892  # Devil's Fork State Park
    set_key US-2893 KFF-2893  # Dreher Island State Park
    set_key US-2894 KFF-2894  # Edisto Beach State Park
    set_key US-2895 KFF-2895  # Givhans Ferry State Park
    set_key US-2896 KFF-2896  # Goodale State Park
    set_key US-2897 KFF-2897  # Hamilton Branch State Park
    set_key US-2898 KFF-2898  # Hickory Knob Resort State Park
    set_key US-2899 KFF-2899  # Hunting Island State Park
    set_key US-2900 KFF-2900  # Huntington Beach State Park
    set_key US-2901 KFF-2901  # Jones Gap State Park
    set_key US-2902 KFF-2902  # Kings Mountain State Park
    set_key US-2903 KFF-2903  # Lake Warren State Park
    set_key US-2904 KFF-2904  # Landsford Canal State Park
    set_key US-2905 KFF-2905  # Lee State Park
    set_key US-2906 KFF-2906  # Little Pee Dee State Park
    set_key US-2907 KFF-2907  # Myrtle Beach State Park
    set_key US-2908 KFF-2908  # Oconee State Park
    set_key US-2909 KFF-2909  # Paris Mountain State Park
    set_key US-2910 KFF-2910  # Poinsett State Park
    set_key US-2911 KFF-2911  # Sadlers Creek State Park
    set_key US-2912 KFF-2912  # Santee State Park
    set_key US-2913 KFF-2913  # Sesquicentennial State Park
    set_key US-2914 KFF-2914  # Table Rock State Park
    set_key US-2915 KFF-2915  # Woods Bay State Park
    set_key US-2916 KFF-2916  # Bear Butte State Park
    set_key US-2917 KFF-2917  # Custer State Park
    set_key US-2918 KFF-2918  # Fort Sisseton State Park
    set_key US-2919 KFF-2919  # Good Earth State Park
    set_key US-2920 KFF-2920  # Hartford Beach State Park
    set_key US-2921 KFF-2921  # Lake Herman State Park
    set_key US-2922 KFF-2922  # Newton Hills State Park
    set_key US-2923 KFF-2923  # Oakwood Lakes State Park
    set_key US-2924 KFF-2924  # Palisades State Park
    set_key US-2925 KFF-2925  # Roy Lake State Park
    set_key US-2926 KFF-2926  # Sica Hollow State Park
    set_key US-2927 KFF-2927  # Union Grove State Park
    set_key US-2928 KFF-2928  # Bicentennial Capitol Mall State Park
    set_key US-2929 KFF-2929  # Big Cypress Tree State Park
    set_key US-2930 KFF-2930  # Big Hill Pond State Park
    set_key US-2931 KFF-2931  # Big Ridge State Park
    set_key US-2932 KFF-2932  # Bledsoe Creek State Park
    set_key US-2933 KFF-2933  # Booker T Washington State Park
    set_key US-2934 KFF-2934  # Burgess Falls State Park
    set_key US-2935 KFF-2935  # Cedars of Lebanon State Park
    set_key US-2936 KFF-2936  # Chickasaw State Park
    set_key US-2937 KFF-2937  # Cordell Hull Birthplace State Park
    set_key US-2938 KFF-2938  # Cove Lake State Park
    set_key US-2939 KFF-2939  # Cumberland Mountain State Park
    set_key US-2940 KFF-2940  # Cummins Falls State Park
    set_key US-2941 KFF-2941  # David Crockett State Park
    set_key US-2942 KFF-2942  # Davy Crockett Birthplace State Park
    set_key US-2943 KFF-2943  # Dunbar Cave State Park
    set_key US-2944 KFF-2944  # Edgar Evins State Park
    set_key US-2945 KFF-2945  # Fall Creek Falls State Park
    set_key US-2946 KFF-2946  # Fort Loudon State Park
    set_key US-2947 KFF-2947  # Fort Pillow State Park
    set_key US-2948 KFF-2948  # Frozen Head State Park
    set_key US-2949 KFF-2949  # Harpeth River State Park
    set_key US-2950 KFF-2950  # Henry Horton State Park
    set_key US-2951 KFF-2951  # Harrison Bay State Park
    set_key US-2952 KFF-2952  # Hiwassee Ocoee State Park
    set_key US-2953 KFF-2953  # Indian Mountain State Park
    set_key US-2954 KFF-2954  # Johnsonville State Park
    set_key US-2955 KFF-2955  # Wilson Cumberland Trail State Park
    set_key US-2956 KFF-2956  # Long Hunter State Park
    set_key US-2957 KFF-2957  # Meeman-Shelby Forest State Park
    set_key US-2958 KFF-2958  # Montgomery Bell State Park
    set_key US-2959 KFF-2959  # Mousetail Landing State Park
    set_key US-2960 KFF-2960  # Nathan Bedford Forrest State Park
    set_key US-2961 KFF-2961  # Natchez Trace State Park
    set_key US-2962 KFF-2962  # Norris Dam State Park
    set_key US-2963 KFF-2963  # Old Stone Fort State Park
    set_key US-2964 KFF-2964  # Panther Creek State Park
    set_key US-2965 KFF-2965  # Paris Landing State Park
    set_key US-2966 KFF-2966  # Pickett State Park
    set_key US-2967 KFF-2967  # Pickwick Landing State Park
    set_key US-2968 KFF-2968  # Pinson Mounds State Park
    set_key US-2969 KFF-2969  # Port Royal State Park
    set_key US-2970 KFF-2970  # Red Clay State Park
    set_key US-2971 KFF-2971  # Reelfoot Lake State Park
    set_key US-2972 KFF-2972  # Roan Mountain State Park
    set_key US-2973 KFF-2973  # Rock Island State Park
    set_key US-2974 KFF-2974  # Rocky Fork State Park
    set_key US-2975 KFF-2975  # Seven Islands Birding State Park
    set_key US-2976 KFF-2976  # Sgt. Alvin C. York State Park
    set_key US-2977 KFF-2977  # South Cumberland State Park
    set_key US-2978 KFF-2978  # Standing Stone State Park
    set_key US-2979 KFF-2979  # Sycamore Shoals State Park
    set_key US-2980 KFF-2980  # Tims Ford State Park
    set_key US-2981 KFF-2981  # T.O. Fuller State Park
    set_key US-2982 KFF-2982  # Warriors' Path State Park
    set_key US-2983 KFF-2983  # Abilene State Park
    set_key US-2984 KFF-2984  # Atlanta State Park
    set_key US-2985 KFF-2985  # Balmorhea State Park
    set_key US-2986 KFF-2986  # Bastrop State Park
    set_key US-2987 KFF-2987  # Bentsen-Rio Grande Valley State Park
    set_key US-2988 KFF-2988  # Big Bend Ranch State Park
    set_key US-2989 KFF-2989  # Big Spring State Park
    set_key US-2990 KFF-2990  # Blanco State Park
    set_key US-2991 KFF-2991  # Bonham State Park
    set_key US-2992 KFF-2992  # Brazos Bend State Park
    set_key US-2993 KFF-2993  # Buescher State Park
    set_key US-2994 KFF-2994  # Caddo Lake State Park
    set_key US-2995 KFF-2995  # Caprock Canyons State Park
    set_key US-2996 KFF-2996  # Cedar Hill State Park
    set_key US-2997 KFF-2997  # Choke Canyon State Park
    set_key US-2998 KFF-2998  # Cleburne State Park
    set_key US-2999 KFF-2999  # Colorado Bend State Park
    set_key US-3000 KFF-3000  # Cooper Lake State Park
    set_key US-3001 KFF-3001  # Copper Breaks State Park
    set_key US-3002 KFF-3002  # Daingerfield State Park
    set_key US-3003 KFF-3003  # Davis Mountains State Park
    set_key US-3004 KFF-3004  # Dinosaur Valley State Park
    set_key US-3005 KFF-3005  # Eisenhower State Park
    set_key US-3006 KFF-3006  # Estero Llano Grande State Park
    set_key US-3007 KFF-3007  # Fairfield Lake State Park
    set_key US-3008 KFF-3008  # Falcon State Park
    set_key US-3009 KFF-3009  # Fort Boggy State Park
    set_key US-3010 KFF-3010  # Fort Parker State Park
    set_key US-3011 KFF-3011  # Fort Richardson State Park
    set_key US-3012 KFF-3012  # Franklin Mountains State Park
    set_key US-3013 KFF-3013  # Galveston Island State Park
    set_key US-3014 KFF-3014  # Garner State Park
    set_key US-3015 KFF-3015  # Goliad State Park
    set_key US-3016 KFF-3016  # Goose Island State Park
    set_key US-3017 KFF-3017  # Guadalupe River State Park
    set_key US-3018 KFF-3018  # Hueco Tanks State Park
    set_key US-3019 KFF-3019  # Huntsville State Park
    set_key US-3020 KFF-3020  # Inks Lake State Park
    set_key US-3021 KFF-3021  # Kickapoo Cavern State Park
    set_key US-3022 KFF-3022  # Lake Arrowhead State Park
    set_key US-3023 KFF-3023  # Lake Bob Sandlin State Park
    set_key US-3024 KFF-3024  # Lake Brownwood State Park
    set_key US-3025 KFF-3025  # Lake Casa Blanca International State Park
    set_key US-3026 KFF-3026  # Lake Colorado City State Park
    set_key US-3027 KFF-3027  # Lake Corpus Christi State Park
    set_key US-3028 KFF-3028  # Lake Livingston State Park
    set_key US-3029 KFF-3029  # Lake Mineral Wells State Park
    set_key US-3030 KFF-3030  # Lake Somerville State Park
    set_key US-3031 KFF-3031  # Lake Tawakoni State Park
    set_key US-3032 KFF-3032  # Lake Whitney State Park
    set_key US-3033 KFF-3033  # Lockhart State Park
    set_key US-3034 KFF-3034  # Longhorn Cavern State Park
    set_key US-3035 KFF-3035  # Lyndon B. Johnson State Park
    set_key US-3036 KFF-3036  # Martin Creek Lake State Park
    set_key US-3037 KFF-3037  # Martin Dies, Jr. State Park
    set_key US-3038 KFF-3038  # McKinney Falls State Park
    set_key US-3039 KFF-3039  # Meridian State Park
    set_key US-3040 KFF-3040  # Mission Tejas State Park
    set_key US-3041 KFF-3041  # Monahans Sandhills State Park
    set_key US-3042 KFF-3042  # Mother Neff State Park
    set_key US-3043 KFF-3043  # Mustang Island State Park
    set_key US-3044 KFF-3044  # Old Tunnel State Park
    set_key US-3045 KFF-3045  # Palmetto State Park
    set_key US-3046 KFF-3046  # Palo Duro Canyon State Park
    set_key US-3047 KFF-3047  # Palo Pinto Mountain State Park
    set_key US-3048 KFF-3048  # Pedernales Falls State Park
    set_key US-3049 KFF-3049  # Possum Kingdom State Park
    set_key US-3050 KFF-3050  # Purtis Creek State Park
    set_key US-3051 KFF-3051  # Ray Roberts Lake State Park
    set_key US-3052 KFF-3052  # Resaca De La Palma State Park
    set_key US-3053 KFF-3053  # San Angelo State Park
    set_key US-3054 KFF-3054  # Sea Rim State Park
    set_key US-3055 KFF-3055  # Seminole Canyon State Park
    set_key US-3056 KFF-3056  # Sheldon Lake State Park
    set_key US-3057 KFF-3057  # South Llano River State Park
    set_key US-3058 KFF-3058  # Stephen F. Austin State Park
    set_key US-3059 KFF-3059  # Tyler State Park
    set_key US-3060 KFF-3060  # Village Creek State Park
    set_key US-3061 KFF-3061  # Walter Umphrey State Park
    set_key US-3062 KFF-3062  # Antelope Island State Park
    set_key US-3063 KFF-3063  # Bear Lake State Park
    set_key US-3064 KFF-3064  # Camp Floyd/Stagecoach Inn State Park
    set_key US-3065 KFF-3065  # Coral Pink Sand Dunes State Park
    set_key US-3066 KFF-3066  # Dead Horse Point State Park
    set_key US-3067 KFF-3067  # Deer Creek State Park
    set_key US-3068 KFF-3068  # East Canyon State Park
    set_key US-3069 KFF-3069  # Edge of the Cedars State Park
    set_key US-3070 KFF-3070  # Escalante Petrified Forest State Park
    set_key US-3071 KFF-3071  # Fremont Indian State Park
    set_key US-3072 KFF-3072  # Frontier Homestead State Park
    set_key US-3073 KFF-3073  # Goblin Valley State Park
    set_key US-3074 KFF-3074  # Goosenecks State Park
    set_key US-3075 KFF-3075  # Great Salt Lake State Park
    set_key US-3076 KFF-3076  # Green River State Park
    set_key US-3077 KFF-3077  # Gunlock State Park
    set_key US-3078 KFF-3078  # Huntington State Park
    set_key US-3079 KFF-3079  # Hyrum State Park
    set_key US-3080 KFF-3080  # Jordanelle State Park
    set_key US-3081 KFF-3081  # Kodachrome Basin State Park
    set_key US-3082 KFF-3082  # Millsite State Park
    set_key US-3083 KFF-3083  # Otter Creek State Park
    set_key US-3084 KFF-3084  # Palisade State Park
    set_key US-3085 KFF-3085  # Piute State Park
    set_key US-3086 KFF-3086  # Quail Creek State Park
    set_key US-3087 KFF-3087  # Red Fleet State Park
    set_key US-3088 KFF-3088  # Rockport State Park
    set_key US-3089 KFF-3089  # Sand Hollow State Park
    set_key US-3090 KFF-3090  # Scofield State Park
    set_key US-3091 KFF-3091  # Snow Canyon State Park
    set_key US-3092 KFF-3092  # Starvation (Fred Hayes)
    set_key US-3093 KFF-3093  # Steinaker State Park
    set_key US-3094 KFF-3094  # Utah Lake State Park
    set_key US-3095 KFF-3095  # Wasatch Mountain State Park
    set_key US-3096 KFF-3096  # Willard Bay State Park
    set_key US-3097 KFF-3097  # Yuba State Park
    set_key US-3098 KFF-3098  # Alburg Dunes State Park
    set_key US-3099 KFF-3099  # Allis State Park
    set_key US-3100 KFF-3100  # Big Deer State Park
    set_key US-3101 KFF-3101  # Bomoseen State Park
    set_key US-3102 KFF-3102  # Boulder Beach State Park
    set_key US-3103 KFF-3103  # Branbury State Park
    set_key US-3104 KFF-3104  # Brighton State Park
    set_key US-3105 KFF-3105  # Burton Island State Park
    set_key US-3106 KFF-3106  # Button Bay State Park
    set_key US-3107 KFF-3107  # Camels Hump State Park
    set_key US-3108 KFF-3108  # Camp Plymouth State Park
    set_key US-3109 KFF-3109  # Coolidge State Park
    set_key US-3110 KFF-3110  # Crystal Lake State Park
    set_key US-3111 KFF-3111  # D.A.R. State Park
    set_key US-3112 KFF-3112  # Elmore State Park
    set_key US-3113 KFF-3113  # Emerald Lake State Park
    set_key US-3114 KFF-3114  # Fort Dummer State Park
    set_key US-3115 KFF-3115  # Gifford Woods State Park
    set_key US-3116 KFF-3116  # Grand Isle State Park
    set_key US-3117 KFF-3117  # Green River Reservoir State Park
    set_key US-3118 KFF-3118  # Halfmoon Pond State Park
    set_key US-3119 KFF-3119  # Hazens Notch State Park
    set_key US-3120 KFF-3120  # Jamaica State Park
    set_key US-3121 KFF-3121  # Kamp Kill Kare State Park
    set_key US-3122 KFF-3122  # Kettle Pond State Park
    set_key US-3123 KFF-3123  # Kingsland Bay State Park
    set_key US-3124 KFF-3124  # Knight Island State Park
    set_key US-3125 KFF-3125  # Knight Point State Park
    set_key US-3126 KFF-3126  # Lake Carmi State Park
    set_key US-3127 KFF-3127  # Lake St. Catherine State Park
    set_key US-3128 KFF-3128  # Lake Shaftsbury State Park
    set_key US-3129 KFF-3129  # Little River State Park
    set_key US-3130 KFF-3130  # Lowell Lake State Park
    set_key US-3131 KFF-3131  # Maidstone State Park
    set_key US-3132 KFF-3132  # Molly Stark State Park
    set_key US-3133 KFF-3133  # Mount Ascutney State Park
    set_key US-3134 KFF-3134  # Mount Philo State Park
    set_key US-3135 KFF-3135  # New Discovery State Park
    set_key US-3136 KFF-3136  # Niquette Bay State Park
    set_key US-3137 KFF-3137  # North Hero State Park
    set_key US-3138 KFF-3138  # Quechee State Park
    set_key US-3139 KFF-3139  # Ricker Pond State Park
    set_key US-3140 KFF-3140  # Sand Bar State Park
    set_key US-3141 KFF-3141  # Sentinel Rock State Park
    set_key US-3142 KFF-3142  # Seyon Lodge State Park
    set_key US-3143 KFF-3143  # Silver Lake State Park
    set_key US-3144 KFF-3144  # Smugglers' Notch State Park
    set_key US-3145 KFF-3145  # Stillwater State Park
    set_key US-3146 KFF-3146  # Sweet Pond State Park
    set_key US-3147 KFF-3147  # Thetford Hill State Park
    set_key US-3148 KFF-3148  # Townshend State Park
    set_key US-3149 KFF-3149  # Underhill State Park
    set_key US-3150 KFF-3150  # Waterbury Center State Park
    set_key US-3151 KFF-3151  # Wilgus State Park
    set_key US-3152 KFF-3152  # Woodford State Park
    set_key US-3153 KFF-3153  # Woods Island State Park
    set_key US-3154 KFF-3154  # Alta Lake State Park
    set_key US-3155 KFF-3155  # Anderson Lake State Park
    set_key US-3156 KFF-3156  # Battle Ground Lake State Park
    set_key US-3157 KFF-3157  # Bayview State Park
    set_key US-3158 KFF-3158  # Beacon Rock State Park
    set_key US-3159 KFF-3159  # Belfair State Park
    set_key US-3160 KFF-3160  # Birch Bay State Park
    set_key US-3161 KFF-3161  # Blake Island State Park
    set_key US-3162 KFF-3162  # Blind Island State Park
    set_key US-3163 KFF-3163  # Bogachiel State Park
    set_key US-3164 KFF-3164  # Bottle Beach State Park
    set_key US-3165 KFF-3165  # Bridgeport State Park
    set_key US-3166 KFF-3166  # Bridle Trails State Park
    set_key US-3167 KFF-3167  # Brooks Memorial State Park
    set_key US-3168 KFF-3168  # Cama Beach State Park
    set_key US-3169 KFF-3169  # Camano Island State Park
    set_key US-3170 KFF-3170  # Cape Disappointment State Park
    set_key US-3171 KFF-3171  # Centennial Trail State Park
    set_key US-3172 KFF-3172  # Clark Island State Park
    set_key US-3173 KFF-3173  # Columbia Hills State Park
    set_key US-3174 KFF-3174  # Conconully State Park
    set_key US-3175 KFF-3175  # Crawford State Park
    set_key US-3176 KFF-3176  # Curlew Lake State Park
    set_key US-3177 KFF-3177  # Cutts Island State Park
    set_key US-3178 KFF-3178  # Daroga State Park
    set_key US-3179 KFF-3179  # Dash Point State Park
    set_key US-3180 KFF-3180  # Deception Pass State Park
    set_key US-3181 KFF-3181  # Doe Island State Park
    set_key US-3182 KFF-3182  # Dosewallips State Park
    set_key US-3183 KFF-3183  # Doug's Beach State Park
    set_key US-3184 KFF-3184  # Eagle Island State Park
    set_key US-3185 KFF-3185  # Federation Forest State Park
    set_key US-3186 KFF-3186  # Fields Spring State Park
    set_key US-3187 KFF-3187  # Flaming Geyser State Park
    set_key US-3188 KFF-3188  # Fort Casey State Park
    set_key US-3189 KFF-3189  # Fort Columbia State Park
    set_key US-3190 KFF-3190  # Fort Ebey State Park
    set_key US-3191 KFF-3191  # Fort Flagler State Park
    set_key US-3192 KFF-3192  # Fort Simcoe State Park
    set_key US-3193 KFF-3193  # Fort Townsend State Park
    set_key US-3194 KFF-3194  # Fort Worden State Park
    set_key US-3195 KFF-3195  # Goldendale Observatory State Park
    set_key US-3196 KFF-3196  # Grayland Beach State Park
    set_key US-3197 KFF-3197  # Griffiths-Priday Ocean State Park
    set_key US-3198 KFF-3198  # Harstine Island State Park
    set_key US-3199 KFF-3199  # Hope Island State Park
    set_key US-3200 KFF-3200  # Hope Island Marine State Park
    set_key US-3201 KFF-3201  # Ike Kinswa State Park
    set_key US-3202 KFF-3202  # Illahee State Park
    set_key US-3203 KFF-3203  # Iron Horse State Park
    set_key US-3204 KFF-3204  # James Island State Park
    set_key US-3205 KFF-3205  # Jarrell Cove State Park
    set_key US-3206 KFF-3206  # Joemma Beach State Park
    set_key US-3207 KFF-3207  # Jones Island State Park
    set_key US-3208 KFF-3208  # Joseph Whidbey State Park
    set_key US-3209 KFF-3209  # Kanaskat-Palmer State Park
    set_key US-3210 KFF-3210  # Kinney Point State Park
    set_key US-3211 KFF-3211  # Kitsap Memorial State Park
    set_key US-3212 KFF-3212  # Kopachuck State Park
    set_key US-3213 KFF-3213  # Lake Chelan State Park
    set_key US-3214 KFF-3214  # Lake Easton State Park
    set_key US-3215 KFF-3215  # Lake Isabella State Park
    set_key US-3216 KFF-3216  # Lake Sammamish State Park
    set_key US-3217 KFF-3217  # Lake Sylvia State Park
    set_key US-3218 KFF-3218  # Lake Wenatchee State Park
    set_key US-3219 KFF-3219  # Larrabee State Park
    set_key US-3220 KFF-3220  # Leadbetter Point State Park
    set_key US-3221 KFF-3221  # Lewis and Clark State Park
    set_key US-3222 KFF-3222  # Lewis and Clark Trail State Park
    set_key US-3223 KFF-3223  # Lime Kiln Point State Park
    set_key US-3224 KFF-3224  # Lincoln Rock State Park
    set_key US-3225 KFF-3225  # Lyons Ferry State Park
    set_key US-3226 KFF-3226  # Loomis Lake State Park
    set_key US-3227 KFF-3227  # Manchester State Park
    set_key US-3228 KFF-3228  # Maryhill State Park
    set_key US-3229 KFF-3229  # Matia Island State Park
    set_key US-3230 KFF-3230  # McMicken Island State Park
    set_key US-3231 KFF-3231  # Millersylvania State Park
    set_key US-3232 KFF-3232  # Moran State Park
    set_key US-3233 KFF-3233  # Mount Pilchuck State Park
    set_key US-3234 KFF-3234  # Mount Spokane State Park
    set_key US-3235 KFF-3235  # Mystery Bay State Park
    set_key US-3236 KFF-3236  # Nolte State Park
    set_key US-3237 KFF-3237  # Obstruction Pass State Park
    set_key US-3238 KFF-3238  # Ocean City State Park
    set_key US-3239 KFF-3239  # Olallie State Park
    set_key US-3240 KFF-3240  # Olmstead Place State Park
    set_key US-3241 KFF-3241  # Pacific Beach State Park
    set_key US-3242 KFF-3242  # Pacific Pines State Park
    set_key US-3243 KFF-3243  # Palouse Falls State Park
    set_key US-3244 KFF-3244  # Paradise Point State Park
    set_key US-3245 KFF-3245  # Patos Island State Park
    set_key US-3246 KFF-3246  # Peace Arch State Park
    set_key US-3247 KFF-3247  # Pearrygin Lake State Park
    set_key US-3248 KFF-3248  # Penrose Point State Park
    set_key US-3249 KFF-3249  # Peshastin Pinnacles State Park
    set_key US-3250 KFF-3250  # Pleasant Harbor State Park
    set_key US-3251 KFF-3251  # Posey Island State Park
    set_key US-3252 KFF-3252  # Potholes State Park
    set_key US-3253 KFF-3253  # Potlatch State Park
    set_key US-3254 KFF-3254  # Rainbow Falls State Park
    set_key US-3255 KFF-3255  # Rasar State Park
    set_key US-3256 KFF-3256  # Reed Island State Park
    set_key US-3257 KFF-3257  # Riverside State Park
    set_key US-3258 KFF-3258  # Rockport State Park
    set_key US-3259 KFF-3259  # Sacajawea State Park
    set_key US-3260 KFF-3260  # Saddlebag Island State Park
    set_key US-3261 KFF-3261  # Saint Edward State Park
    set_key US-3262 KFF-3262  # Saltwater State Park
    set_key US-3263 KFF-3263  # Scenic Beach State Park
    set_key US-3264 KFF-3264  # Schafer State Park
    set_key US-3265 KFF-3265  # Seaquest State Park
    set_key US-3266 KFF-3266  # Sequim Bay State Park
    set_key US-3267 KFF-3267  # Shine Tidelands State Park
    set_key US-3268 KFF-3268  # Skagit Island State Park
    set_key US-3269 KFF-3269  # Skull Island State Park
    set_key US-3270 KFF-3270  # South Whidbey State Park
    set_key US-3271 KFF-3271  # Spencer Spit State Park
    set_key US-3272 KFF-3272  # Squak Mountain State Park
    set_key US-3273 KFF-3273  # Squilchuck State Park
    set_key US-3274 KFF-3274  # Steamboat Rock State Park
    set_key US-3275 KFF-3275  # Steptoe Butte State Park
    set_key US-3276 KFF-3276  # Steptoe Battlefield State Park
    set_key US-3277 KFF-3277  # Stretch Point State Park
    set_key US-3278 KFF-3278  # Stuart Island State Park
    set_key US-3279 KFF-3279  # Sucia Island State Park
    set_key US-3280 KFF-3280  # Sun Lakes-Dry Falls State Park
    set_key US-3281 KFF-3281  # Tolmie State Park
    set_key US-3282 KFF-3282  # Triton Cove State Park
    set_key US-3283 KFF-3283  # Turn Island State Park
    set_key US-3284 KFF-3284  # Twanoh State Park
    set_key US-3285 KFF-3285  # Twenty-Five Mile Creek State Park
    set_key US-3286 KFF-3286  # Twin Harbors State Park
    set_key US-3287 KFF-3287  # Wallace Falls State Park
    set_key US-3288 KFF-3288  # Wenatchee Confluence State Park
    set_key US-3289 KFF-3289  # Westhaven State Park
    set_key US-3290 KFF-3290  # Westport Light State Park
    set_key US-3291 KFF-3291  # Yakima Sportsman State Park
    set_key US-3292 KFF-3292  # Bear River State Park
    set_key US-3293 KFF-3293  # Boysen State Park
    set_key US-3294 KFF-3294  # Buffalo Bill State Park
    set_key US-3295 KFF-3295  # Curt Gowdy State Park
    set_key US-3296 KFF-3296  # Edness Kimball Wilkins State Park
    set_key US-3297 KFF-3297  # Glendo State Park
    set_key US-3298 KFF-3298  # Guernsey State Park
    set_key US-3299 KFF-3299  # Hot Springs State Park
    set_key US-3300 KFF-3300  # Keyhole State Park
    set_key US-3301 KFF-3301  # Seminoe State Park
    set_key US-3302 KFF-3302  # Sinks Canyon State Park
    set_key US-3303 KFF-3303  # Agate Falls Scenic Site
    set_key US-3304 KFF-3304  # Bass River State Recreation Area
    set_key US-3305 KFF-3305  # Bay City State Recreation Area
    set_key US-3306 KFF-3306  # Bond Falls Scenic Site
    set_key US-3307 KFF-3307  # Cambridge Junction State Historical Park
    set_key US-3308 KFF-3308  # Father Marquette Memorial National Memorial
    set_key US-3309 KFF-3309  # Fayette Historic State Park
    set_key US-3310 KFF-3310  # Fort Custer State Recreation Area
    set_key US-3311 KFF-3311  # Fort Wilkins State Historical Park
    set_key US-3312 KFF-3312  # Highland State Recreation Area
    set_key US-3313 KFF-3313  # Holly State Recreation Area
    set_key US-3314 KFF-3314  # Ionia State Recreation Area
    set_key US-3315 KFF-3315  # Island Lake State Recreation Area
    set_key US-3316 KFF-3316  # Lake Hudson State Recreation Area
    set_key US-3317 KFF-3317  # Laughing Whitefish Falls State Park
    set_key US-3318 KFF-3318  # Lime Island State Recreation Area
    set_key US-3319 KFF-3319  # Menominee River State Recreation Area
    set_key US-3320 KFF-3320  # Metamora-Hadley State Recreation Area
    set_key US-3321 KFF-3321  # Ortonville State Recreation Area
    set_key US-3322 KFF-3322  # Pinckney State Recreation Area
    set_key US-3323 KFF-3323  # Pontiac Lake State Recreation Area
    set_key US-3324 KFF-3324  # Proud Lake State Recreation Area
    set_key US-3325 KFF-3325  # Rifle River State Recreation Area
    set_key US-3326 KFF-3326  # Rockport State Recreation Area
    set_key US-3327 KFF-3327  # Sanilac Petroglyphs State Park
    set_key US-3328 KFF-3328  # Sturgeon Point State Park
    set_key US-3329 KFF-3329  # Tippy Dam State Recreation Area
    set_key US-3330 KFF-3330  # Wagner Falls Scenic Site
    set_key US-3331 KFF-3331  # Waterloo State Recreation Area
    set_key US-3332 KFF-3332  # Watkins Lake State Park
    set_key US-3333 KFF-3333  # Wetzel State Recreation Area
    set_key US-3334 KFF-3334  # Yankee Springs State Recreation Area
    set_key US-3335 KFF-3335  # Arrow Rock State Historic Site
    set_key US-3336 KFF-3336  # Battle of Athens State Historic Site
    set_key US-3337 KFF-3337  # Battle of Carthage State Historic Site
    set_key US-3338 KFF-3338  # Battle of Island Mound State Historic Site
    set_key US-3339 KFF-3339  # Battle of Lexington State Historic Site
    set_key US-3340 KFF-3340  # Battle of Pilot Knob State Historic Site
    set_key US-3341 KFF-3341  # Bollinger Mill State Historic Site
    set_key US-3342 KFF-3342  # Boone's Lick State Historic Site
    set_key US-3343 KFF-3343  # Bothwell Lodge State Historic Site
    set_key US-3344 KFF-3344  # Clark's Hill/Norton State Historic Site
    set_key US-3345 KFF-3345  # Confederate Memorial State Historic Site
    set_key US-3346 KFF-3346  # Deutschheim State Historic Site
    set_key US-3347 KFF-3347  # Dillard Mill State Historic Site
    set_key US-3348 KFF-3348  # Felix Valle House State Historic Site
    set_key US-3349 KFF-3349  # First Missouri State Capitol State Historic Site
    set_key US-3350 KFF-3350  # Gen. John J. Pershing Boyhood Home State Historic Site
    set_key US-3351 KFF-3351  # Gov. Daniel Dunklin's Grave State Historic Site
    set_key US-3352 KFF-3352  # Hunter-Dawson State Historic Site
    set_key US-3353 KFF-3353  # Iliniwek Village State Historic Site
    set_key US-3354 KFF-3354  # Jewell Cemetery State Historic Site
    set_key US-3355 KFF-3355  # Locust Creek Covered Bridge State Historic Site
    set_key US-3356 KFF-3356  # Mark Twain Birthplace State Historic Site
    set_key US-3357 KFF-3357  # Mastodon State Historic Site
    set_key US-3358 KFF-3358  # Missouri Mines State Historic Site
    set_key US-3359 KFF-3359  # Missouri State Museum/Jefferson Landing State Historic Site
    set_key US-3360 KFF-3360  # Nathan Boone Homestead State Historic Site
    set_key US-3361 KFF-3361  # Osage Village State Historic Site
    set_key US-3362 KFF-3362  # Sandy Creek Covered Bridge State Historic Site
    set_key US-3363 KFF-3363  # Sappington Cemetery State Historic Site
    set_key US-3364 KFF-3364  # Scott Joplin House State Historic Site
    set_key US-3365 KFF-3365  # Thomas Hart Benton Home and Studio State Historic Site
    set_key US-3366 KFF-3366  # Towosahgy State Historic Site
    set_key US-3367 KFF-3367  # Union Covered Bridge State Historic Site
    set_key US-3368 KFF-3368  # Watkins Woolen Mill State Historic Site
    set_key US-3369 KFF-3369  # Bryant Creek State Park
    set_key US-3370 KFF-3370  # Eleven Point State Park
    set_key US-3371 KFF-3371  # Nebraska National Forest
    set_key US-3372 KFF-3372  # Samuel R McKelvie National Forest
    set_key US-3373 NIL-0000  # Chimney Rock National Historic Site (no WWFF)
    set_key US-3375 KFF-3375  # Stolley National Historic Site
    set_key US-3376 KFF-3376  # Victoria Springs State Recreation Area
    set_key US-3377 KFF-3377  # Schilling Wildlife Management Area
    set_key US-3378 NIL-0000  # Blue Ridge National Parkway (VA); WWFF candidates: KFF-3378, KFF-4590
    set_key US-3379 NIL-0000  # Delaware Water Gap National Recreation Area (PA); WWFF candidates: KFF-3379, KFF-4595
    set_key US-3380 KFF-3380  # Lake Chelan National Recreation Area
    set_key US-3381 KFF-3381  # Mississippi River National Recreation Area
    set_key US-3382 KFF-3382  # John National Wild and Scenic River
    set_key US-3383 KFF-3383  # Bald Mountain State Recreation Area
    set_key US-3384 KFF-3384  # Brighton State Recreation Area
    set_key US-3385 KFF-3385  # Mt. St. Helens National Monument
    set_key US-3386 KFF-3386  # Bears Ears BLM National Monument
    set_key US-3387 KFF-3387  # Thompson Chain of Lakes State Park
    set_key US-3389 KFF-3389  # Spooner Lake and Backcountry State Park
    set_key US-3390 KFF-3390  # River Island State Park
    set_key US-3391 KFF-3391  # Na Pali Coast State Park
    set_key US-3392 KFF-6814  # Kachemak Bay Wilderness
    set_key US-3393 KFF-3393  # Admiral William Standley State Recreation Area
    set_key US-3394 KFF-3394  # Albany State Marine Reserve
    set_key US-3395 KFF-3395  # Anderson Marsh State Historical Park
    set_key US-3396 KFF-3396  # Antelope Valley Poppy Reserve State Conservation Area
    set_key US-3397 KFF-3397  # Antelope Valley Indian Museum State Historical Park
    set_key US-3398 KFF-3398  # Armstrong Redwoods Reserve State Conservation Area
    set_key US-3399 KFF-3399  # Asilomar State State Beach
    set_key US-3400 KFF-3400  # Auburn State Recreation Area
    set_key US-3401 KFF-3401  # Austin Creek State Recreation Area
    set_key US-3402 KFF-3402  # Azalea Reserve State Conservation Area
    set_key US-3403 KFF-3403  # Bale Grist Mill State Historical Park
    set_key US-3404 KFF-3404  # Bean Hollow State Beach
    set_key US-3405 KFF-3405  # Benbow Lake State Recreation Area
    set_key US-3407 KFF-3407  # Benicia State Recreation Area
    set_key US-3408 KFF-3408  # Bethany Reservoir State Recreation Area
    set_key US-3411 KFF-3411  # Bolsa Chica State Beach
    set_key US-3412 KFF-3412  # California Citrus State Historical Park
    set_key US-3416 KFF-3416  # Castaic Lake State Recreation Area
    set_key US-3417 KFF-3417  # Castro Adobe Park
    set_key US-3418 KFF-3418  # Cayucos State Beach
    set_key US-3419 KFF-3419  # Chumash Painted Cave State Historical Park
    set_key US-3421 KFF-3421  # Colonel Allensworth State Historical Park
    set_key US-3423 KFF-3423  # Colusa-Sacramento River State Recreation Area
    set_key US-3425 KFF-3425  # Dockweiler State Beach
    set_key US-3426 KFF-3426  # Doheny State Beach
    set_key US-3427 KFF-3427  # McLaughlin Eastshore State Park
    set_key US-3429 KFF-3429  # Emeryville Crescent State Marine Reserve
    set_key US-3430 KFF-3430  # Emma Wood State Beach
    set_key US-3431 KFF-3431  # Empire Mine State Historical Park
    set_key US-3432 KFF-3432  # Folsom Lake State Recreation Area
    set_key US-3434 KFF-3434  # Fort Humboldt State Historical Park
    set_key US-3435 KFF-3435  # Fort Ross State Historical Park
    set_key US-3436 KFF-3436  # Fort Tejon State Historical Park
    set_key US-3437 KFF-3437  # Franks Tract State Recreation Area
    set_key US-3438 KFF-3438  # Greenwood State Beach
    set_key US-3439 KFF-3439  # Half Moon Bay State Beach
    set_key US-3440 KFF-3440  # Hatton Canyon State Park
    set_key US-3441 KFF-3441  # Hearst San Simeon State Historic Site
    set_key US-3443 KFF-3443  # Hollister Hills State Vehicle Recreational Area
    set_key US-3444 KFF-3444  # Hungry Valley State Vehicle Recreational Area
    set_key US-3445 KFF-3445  # Huntington State Beach
    set_key US-3446 KFF-3446  # Indian Grinding Rock State Historical Park
    set_key US-3447 KFF-3447  # Indio Hills Palms State Park
    set_key US-3448 KFF-3448  # Jack London State Historical Park
    set_key US-3449 KFF-3449  # John B. Dewitt Redwoods Reserve State Conservation Area
    set_key US-3450 KFF-3450  # John Little Reserve State Conservation Area
    set_key US-3451 KFF-3451  # Kenneth Hahn State Recreation Area
    set_key US-3452 KFF-3452  # Kings State Beach State Beach
    set_key US-3453 KFF-3453  # Kruse Rhododendron Reserve State Conservation Area
    set_key US-3454 KFF-3454  # La Purisima Mission State Historical Park
    set_key US-3455 KFF-3455  # Lake Del Valle State Recreation Area
    set_key US-3456 KFF-3456  # Lake Oroville State Recreation Area
    set_key US-3457 KFF-3457  # Lake Perris State Recreation Area
    set_key US-3458 KFF-3458  # Lake Valley State Recreation Area
    set_key US-3460 KFF-3460  # Leucadia State Beach
    set_key US-3461 KFF-3461  # Lighthouse Field State Beach
    set_key US-3463 KFF-3463  # Los Encinos State Historical Park
    set_key US-3464 KFF-3464  # Los Osos Oaks Reserve State Conservation Area
    set_key US-3465 KFF-3465  # Mailliard Redwoods Reserve State Conservation Area
    set_key US-3466 KFF-3466  # Malakoff Diggins State Historical Park
    set_key US-3467 KFF-3467  # Mandalay State Beach
    set_key US-3468 KFF-3468  # Malibu Lagoon State Beach
    set_key US-3469 KFF-3469  # Manresa State Beach
    set_key US-3470 KFF-3470  # Marconi Conference Center State Historical Park
    set_key US-3471 KFF-3471  # Marina State Beach
    set_key US-3473 KFF-3473  # Martial Cottle Park State Recreation Area
    set_key US-3474 KFF-3474  # Mono Lake Tufa Reserve State Conservation Area
    set_key US-3475 KFF-3475  # Montara Beach and McNee Ranch State Beach
    set_key US-3477 KFF-3477  # Monterey State Beach
    set_key US-3478 KFF-3478  # Montgomery Woods Reserve State Conservation Area
    set_key US-3479 KFF-3479  # Moonlight State Beach
    set_key US-3480 KFF-3480  # Morro Strand State Beach
    set_key US-3481 KFF-3481  # Moss Landing State Beach
    set_key US-3482 KFF-3482  # Natural Bridges State Beach
    set_key US-3483 KFF-3483  # Atlanta National Waterfowl Production Area (NAME)
    set_key US-3484 KFF-3484  # Gosper National Wildlife Management Area
    set_key US-3485 KFF-3485  # Jensen Lagoon National Waterfowl Production Area
    set_key US-3486 KFF-3486  # Moger National Waterfowl Production Area
    set_key US-3487 KFF-3487  # DeSoto National Wildlife Refuge (NE)
    set_key US-3488 KFF-3488  # Alberding Lagoon National Wildlife Management Area
    set_key US-3489 KFF-3489  # Massie National Waterfowl Production Area
    set_key US-3490 KFF-3490  # Smith Lagoon National Waterfowl Production Area
    set_key US-3491 KFF-3491  # Lake Wanahoo State Recreation Area
    set_key US-3492 KFF-3492  # Willa Cather Memorial Prairie State Historic Site
    set_key US-3495 KFF-3495  # Battleship Texas State Historic Site
    set_key US-3496 KFF-3496  # Davis Hill State Park
    set_key US-3497 KFF-3497  # Devil's Sinkhole State Conservation Area
    set_key US-3498 KFF-3498  # Devils River Natural State Conservation Area
    set_key US-3499 KFF-3499  # Enchanted Rock Natural State Conservation Area
    set_key US-3500 KFF-3500  # Fanthorp Inn State Historic Site
    set_key US-3501 KFF-3501  # Fort Leaton State Historic Site
    set_key US-3502 KFF-3502  # Goliad State Historic Site
    set_key US-3503 KFF-3503  # Government Canyon Natural State Conservation Area
    set_key US-3504 KFF-3504  # Hill Country Natural State Conservation Area
    set_key US-3505 KFF-3505  # Honey Creek Natural State Conservation Area
    set_key US-3506 KFF-3506  # Lipantitlan State Historic Site
    set_key US-3507 KFF-3507  # Lost Maples Natural State Conservation Area
    set_key US-3508 KFF-3508  # Monument Hill and Kreische Brewery State Historic Site
    set_key US-3509 KFF-3509  # Port Isabel Lighthouse State Historic Site
    set_key US-3510 KFF-3510  # Powderhorn Ranch State Wildlife Area
    set_key US-3511 KFF-3511  # San Jacinto Battleground State Historic Site
    set_key US-3512 KFF-3512  # Washington on the Brazos State Historic Site
    set_key US-3513 KFF-3513  # David Berger National Memorial
    set_key US-3514 KFF-3514  # Fort Miamis Fallen Timbers Battlefield National Historic Site
    set_key US-3515 KFF-3515  # Lake Milton State Park
    set_key US-3516 KFF-3516  # Wingfoot Lake State Park
    set_key US-3517 KFF-3517  # North Bass Island State Park
    set_key US-3518 KFF-3518  # Middle Bass Island State Park
    set_key US-3519 KFF-3519  # MarbleHead Lighthouse State Park
    set_key US-3520 KFF-3520  # Muskingum River State Park
    set_key US-3521 KFF-6643  # Chapel View Prairie State Conservation Area
    set_key US-3522 KFF-3522  # New Brighton State Beach
    set_key US-3523 KFF-3523  # Oceano Dunes State Recreation Area
    set_key US-3524 KFF-3524  # Ocotillo Wells State Vehicle Recreational Area
    set_key US-3526 KFF-3526  # Old Town San Diego State Historical Park
    set_key US-3527 KFF-3527  # Olompali State Historical Park
    set_key US-3528 KFF-3528  # Pacifica State Beach
    set_key US-3529 KFF-3529  # Pelican State Beach
    set_key US-3530 KFF-3530  # Pescadero State Beach
    set_key US-3531 KFF-3531  # Petaluma Adobe State Historical Park
    set_key US-3532 KFF-3532  # Picacho State Recreation Area
    set_key US-3533 KFF-3533  # Pigeon Point Light Station State Historical Park
    set_key US-3535 KFF-3535  # Pismo State Beach
    set_key US-3536 KFF-3536  # Point Cabrillo Lighthouse State Historical Park
    set_key US-3537 KFF-3537  # Point Dume State Beach
    set_key US-3538 KFF-3538  # Point Lobos Ranch State Park
    set_key US-3539 KFF-3539  # Point Lobos Reserve State Conservation Area
    set_key US-3540 KFF-3540  # Point Montara Light Station State Historical Park
    set_key US-3541 KFF-3541  # Point Sal State Beach
    set_key US-3543 KFF-3543  # Pomponio State Beach
    set_key US-3546 KFF-3546  # Refugio State Beach
    set_key US-3547 KFF-3547  # Reynolds Wayside Campground Park
    set_key US-3548 KFF-3548  # Rio de Los Angeles State Park
    set_key US-3549 KFF-3549  # Robert H. Meyer Memorial State Beach
    set_key US-3550 KFF-3550  # Robert W. Crown Memorial State Beach
    set_key US-3551 KFF-3551  # Salinas River State Beach
    set_key US-3552 KFF-3552  # Salton Sea State Recreation Area
    set_key US-3553 KFF-3553  # San Buenaventura State Beach
    set_key US-3554 KFF-3554  # San Clemente State Beach
    set_key US-3555 KFF-3555  # San Elijo State Beach
    set_key US-3556 KFF-3556  # San Gregorio State Beach
    set_key US-3557 KFF-3557  # San Juan Bautista State Historical Park
    set_key US-3558 KFF-3558  # San Luis Reservoir State Recreation Area
    set_key US-3559 KFF-3559  # San Onofre State Beach
    set_key US-3560 KFF-3560  # San Pasqual Battlefield State Historical Park
    set_key US-3561 KFF-3561  # San Timoteo Canyon State Park
    set_key US-3562 KFF-3562  # Santa Cruz Mission State Historical Park
    set_key US-3563 KFF-3563  # Santa Monica State Beach
    set_key US-3564 KFF-3564  # Santa Susana Pass State Historical Park
    set_key US-3565 KFF-3565  # Schooner Gulch State Beach
    set_key US-3566 KFF-3566  # Seacliff State Beach
    set_key US-3567 KFF-3567  # Shasta State Historical Park
    set_key US-3568 KFF-3568  # Silver Strand State Beach
    set_key US-3569 KFF-3569  # Silverwood Lake State Recreation Area
    set_key US-3570 KFF-3570  # Sonoma State Historical Park
    set_key US-3571 KFF-3571  # Standish-Hickey State Recreation Area
    set_key US-3573 KFF-6995  # Wayne E. Kirch Wildlife Management Area
    set_key US-3574 KFF-3574  # Sunset State Beach
    set_key US-3575 KFF-3575  # Sutter's Fort State Historical Park
    set_key US-3576 KFF-3576  # Tahoe State Recreation Area
    set_key US-3577 KFF-3577  # Thornton State Beach
    set_key US-3578 KFF-3578  # Tijuana Estuary Reserve State Conservation Area
    set_key US-3579 KFF-3579  # Tomo-Kahni State Historical Park
    set_key US-3580 KFF-3580  # Torrey Pines State Beach
    set_key US-3581 KFF-3581  # Torrey Pines Reserve State Conservation Area
    set_key US-3582 KFF-3582  # Trinidad State Beach
    set_key US-3583 KFF-3583  # Tule Elk Reserve State Conservation Area
    set_key US-3584 KFF-3584  # Turlock Lake State Recreation Area
    set_key US-3585 KFF-3585  # Twin Lakes State Beach
    set_key US-3586 KFF-3586  # Verdugo Mountains State Park
    set_key US-3587 KFF-3587  # Ward Creek State Park
    set_key US-3590 KFF-3590  # Weaverville Joss House State Historical Park
    set_key US-3591 KFF-3591  # Westport-Union Landing State Beach
    set_key US-3592 KFF-7182  # Key Pittman Wildlife Management Area
    set_key US-3593 KFF-3593  # Wildwood Canyon State Park
    set_key US-3594 KFF-3594  # Will Rogers State Beach
    set_key US-3595 KFF-3595  # Will Rogers State Historical Park
    set_key US-3596 KFF-3596  # William B. Ide Adobe State Historical Park
    set_key US-3598 KFF-3598  # Woodson Bridge State Recreation Area
    set_key US-3599 KFF-3599  # Zmudowski State Beach
    set_key US-3600 KFF-3600  # Bladon Springs State Park
    set_key US-3602 KFF-3602  # Birmingham Civil Rights National Monument
    set_key US-3603 KFF-3603  # Freedom Riders National Monument
    set_key US-3604 KFF-3604  # Addison Blockhouse State Park
    set_key US-3605 KFF-3605  # Allen David Broussard Catfish Creek Preserve State Park
    set_key US-3606 KFF-3606  # Anclote Key Preserve State Park
    set_key US-3607 KFF-3607  # Beker-Wingate Creek State Park
    set_key US-3608 KFF-3608  # Blackwater Heritage State Trail
    set_key US-3609 KFF-3609  # Bulow Plantation Ruins State Park
    set_key US-3610 KFF-3610  # Cedar Key Museum State Park
    set_key US-3611 KFF-3611  # Cedar Key Scrub Reserve State Conservation Area
    set_key US-3612 KFF-3612  # Charlotte Harbor Preserve State Park
    set_key US-3613 KFF-3613  # Cockroach Bay Preserve State Park
    set_key US-3614 KFF-3614  # Crystal River Preserve State Park
    set_key US-3615 KFF-3615  # Dade Battlefield State Park
    set_key US-3616 KFF-3616  # Dudley Farm State Park
    set_key US-3617 KFF-3617  # Estero Bay Preserve State Park
    set_key US-3618 KFF-3618  # Fakahatchee Strand Preserve State Park
    set_key US-3619 KFF-3619  # Fernandina Plaza State Historic Site
    set_key US-3620 KFF-3620  # Florida Keys Overseas Heritage Trail State Park
    set_key US-3621 KFF-3621  # Fort Foster State Historic Site
    set_key US-3622 KFF-3622  # Fort Mose State Park
    set_key US-3623 KFF-3623  # Fort Zachary Taylor State Park
    set_key US-3624 KFF-3624  # Gainesville-Hawthorne State Trail
    set_key US-3625 KFF-3625  # Gamble Plantation State Park
    set_key US-3626 KFF-3626  # Gamble Rogers Memorial State Recreation Area
    set_key US-3627 KFF-3627  # General James A. Van Fleet State Trail
    set_key US-3628 KFF-3628  # George Crady Bridge Fishing Pier State Park
    set_key US-3629 KFF-3629  # Haw Creek Preserve State Park
    set_key US-3630 KFF-3630  # Indian Key State Park
    set_key US-3631 KFF-3631  # Indian River Lagoon State Park
    set_key US-3632 KFF-3632  # Kissimmee Prairie Preserve State Park
    set_key US-3633 KFF-3633  # Koreshan State Historic Site
    set_key US-3634 KFF-3634  # Lower Wekiva River Preserve State Park
    set_key US-3635 KFF-3635  # Madira Bickel Mound State Historic Site
    set_key US-3636 KFF-3636  # Madison Blue Spring State Park
    set_key US-3637 KFF-3637  # Marjorie Harris Carr Cross State Park
    set_key US-3638 KFF-3638  # Marjorie Kinnan Rawlings State Park
    set_key US-3639 KFF-3639  # Natural Bridge Battlefield State Park
    set_key US-3640 KFF-3640  # Nature Coast State Trail
    set_key US-3641 KFF-3641  # Okeechobee Battlefield State Park
    set_key US-3642 KFF-3642  # Olustee Battlefield State Park
    set_key US-3643 KFF-3643  # Orman House State Park
    set_key US-3644 KFF-3644  # Palatka-St. Augustine State Trail
    set_key US-3645 KFF-3645  # Palatka-to-Lake Butler State Trail
    set_key US-3646 KFF-3646  # Paynes Creek State Park
    set_key US-3647 KFF-3647  # Paynes Prairie Preserve State Park
    set_key US-3648 KFF-3648  # Pumpkin Hill Creek Preserve State Park
    set_key US-3649 KFF-3649  # River Rise Preserve State Park
    set_key US-3650 KFF-3650  # Rock Springs Run State Park
    set_key US-3651 KFF-3651  # San Felasco Hammock Preserve State Park
    set_key US-3652 KFF-3652  # San Marcos de Apalache State Park
    set_key US-3653 KFF-3653  # San Pedro Underwater Archaeological Preserve State Park
    set_key US-3654 KFF-3654  # Savannas Preserve State Park
    set_key US-3655 KFF-3655  # Seabranch Preserve State Park
    set_key US-3656 KFF-3656  # South Fork State Park
    set_key US-3657 KFF-3657  # St. Lucie Inlet Preserve State Park
    set_key US-3658 KFF-3658  # St. Marks River Preserve State Park
    set_key US-3659 KFF-3659  # St. Sebastian River Preserve State Park
    set_key US-3660 KFF-3660  # Suwannee River Wilderness State Trail
    set_key US-3661 KFF-3661  # Tallahassee-St. Marks Historic Railroad State Trail
    set_key US-3662 KFF-3662  # Tarkiln Bayou Preserve State Park
    set_key US-3663 KFF-3663  # Terra Ceia Preserve State Park
    set_key US-3664 KFF-3664  # Topsail Hill Preserve State Park
    set_key US-3665 KFF-3665  # Waccasassa Bay Preserve State Park
    set_key US-3666 KFF-3666  # Weeki Wachee Springs State Park
    set_key US-3667 KFF-3667  # Withlacoochee State Trail
    set_key US-3668 KFF-3668  # Ybor City Museum State Park
    set_key US-3669 KFF-3669  # Yellow Bluff Fort State Park
    set_key US-3670 KFF-3670  # Yellow River Marsh Preserve State Park
    set_key US-3671 KFF-3671  # Yulee Sugar Mill Ruins State Park
    set_key US-3672 KFF-3672  # Fool Hollow Lake State Recreation Area
    set_key US-3673 KFF-3673  # Tallgrass Prairie Preserve National Conservation Area
    set_key US-3674 KFF-3674  # Paris Springs State Conservation Area
    set_key US-3675 KFF-3675  # Chickasaw National Recreation Area
    set_key US-3676 KFF-3676  # Chickasaw State Park
    set_key US-3677 KFF-3677  # Paul M. Grist State Park
    set_key US-3678 KFF-3678  # Roland Cooper State Park
    set_key US-3679 KFF-3679  # Autauga Wildlife Management Area
    set_key US-3680 KFF-3680  # Barbour Wildlife Management Area
    set_key US-3681 KFF-3681  # Blowing Springs Cave Preserve State Conservation Area
    set_key US-3682 KFF-3682  # Cheaha Wildlife Management Area
    set_key US-3683 KFF-3683  # Choccolocco Wildlife Management Area
    set_key US-3684 KFF-3684  # Coon Creek Preserve State Conservation Area
    set_key US-3685 KFF-3685  # Coosa Wildlife Management Area
    set_key US-3686 KFF-3686  # David K. Nelson Wildlife Management Area
    set_key US-3687 KFF-3687  # Dugger Mountain Wildlife Management Area
    set_key US-3688 KFF-3688  # Fred T Stimpson Wildlife Management Area
    set_key US-3689 KFF-3689  # Freedom Hills Wildlife Management Area
    set_key US-3690 KFF-3690  # Geneva Wildlife Management Area
    set_key US-3691 KFF-3691  # Grand Bay Savanna Complex Wildlife Management Area
    set_key US-3692 KFF-3692  # Heron Bay and Portersville Bay State Fish and Wildlife Area
    set_key US-3693 KFF-3693  # Hollins Wildlife Management Area
    set_key US-3694 KFF-3694  # James D Martin - Skyline Wildlife Management Area
    set_key US-3695 KFF-3695  # Lauderdale Wildlife Management Area
    set_key US-3696 KFF-3696  # Lillian Swamp Complex Preserve State Conservation Area
    set_key US-3697 KFF-3697  # Lowndes Wildlife Management Area
    set_key US-3698 KFF-3698  # Mallard-Fox Creek Wildlife Management Area
    set_key US-3699 KFF-3699  # Mobile-Tensaw Delta Wildlife Management Area
    set_key US-3700 KFF-3700  # Perdido River Wildlife Management Area
    set_key US-3701 KFF-3701  # Pike County Pocosin Complex State Fish and Wildlife Area
    set_key US-3702 KFF-3702  # Red Hills Complex Preserve State Conservation Area
    set_key US-3703 KFF-3703  # Ruffner Mountain Preserve State Conservation Area
    set_key US-3704 KFF-3704  # Sam R Murphy Wildlife Management Area
    set_key US-3705 KFF-3705  # Shoal Creek Preserve State Conservation Area
    set_key US-3706 KFF-3706  # Sipsey Wildlife Management Area
    set_key US-3707 KFF-3707  # Sipsey River Complex Preserve State Conservation Area
    set_key US-3708 KFF-3708  # Splinter Hill Bog Complex Preserve State Conservation Area
    set_key US-3709 KFF-3709  # Turkey Creek Nature Preserve State Conservation Area
    set_key US-3710 KFF-3710  # Upper Delta Wildlife Management Area
    set_key US-3711 KFF-3711  # Weeks Bay Reserve National Conservation Area
    set_key US-3712 KFF-3712  # Wehle State Nature Preserve
    set_key US-3713 KFF-3713  # William R. Ireland, Sr. - Cahaba River Wildlife Management Area
    set_key US-3714 KFF-3714  # Yates Lake Wildlife Management Area
    set_key US-3715 KFF-3715  # Etowah Indian Mounds State Historic Site
    set_key US-3716 KFF-3716  # Fort King George State Historic Site
    set_key US-3717 KFF-3717  # Fort Morris State Historic Site
    set_key US-3718 KFF-3718  # Hardman Farm State Historic Site
    set_key US-3719 KFF-3719  # Hofwyl-Broadfield Plantation State Historic Site
    set_key US-3720 KFF-3720  # Jarrell Plantation State Historic Site
    set_key US-3722 KFF-3722  # New Echota State Historic Site
    set_key US-3723 KFF-3723  # Pickett's Mill Battlefield State Historic Site
    set_key US-3724 KFF-3724  # Roosevelts Little White House State Historic Site
    set_key US-3725 KFF-3725  # Wormsloe State Historic Site
    set_key US-3726 KFF-3726  # Kolomoki Mounds State Park
    set_key US-3727 KFF-3727  # Hart Outdoor Recreation Park
    set_key US-3728 KFF-3728  # Providence Canyon State Recreation Area
    set_key US-3729 KFF-3729  # Rocky Mountain State Recreation Area
    set_key US-3730 KFF-3730  # Altamaha Wildlife Management Area
    set_key US-3731 KFF-3731  # B.F. Grant Wildlife Management Area
    set_key US-3732 KFF-3732  # Bartram Forest Wildlife Management Area
    set_key US-3733 KFF-3733  # Beaverdam Wildlife Management Area
    set_key US-3734 KFF-3734  # Berry College Wildlife Management Area
    set_key US-3735 KFF-3735  # Big Hammock Wildlife Management Area
    set_key US-3736 KFF-3736  # Blanton Creek Wildlife Management Area
    set_key US-3737 KFF-3737  # Bullard Creek Wildlife Management Area
    set_key US-3738 KFF-3738  # Cedar Creek Wildlife Management Area
    set_key US-3739 KFF-3739  # Chickasawhatchee Wildlife Management Area
    set_key US-3740 KFF-3740  # Clayhole Swamp Wildlife Management Area
    set_key US-3741 KFF-3741  # Coosawattee Wildlife Management Area
    set_key US-3742 KFF-3742  # Crockford-Pigeon Mountain Wildlife Management Area
    set_key US-3743 KFF-3743  # Dawson Forest Wildlife Management Area
    set_key US-3744 KFF-3744  # Di-Lane Wildlife Management Area
    set_key US-3745 KFF-3745  # Dixon Bay Wildlife Management Area
    set_key US-3746 KFF-3746  # Dixon Memorial Wildlife Management Area
    set_key US-3747 KFF-3747  # Elbert County Wildlife Management Area
    set_key US-3748 KFF-3748  # Elmodel Wildlife Management Area
    set_key US-3749 KFF-3749  # Flat Tub Wildlife Management Area
    set_key US-3750 KFF-3750  # Flint River Wildlife Management Area
    set_key US-3751 KFF-3751  # Grand Bay Wildlife Management Area
    set_key US-3752 KFF-3752  # Griffin Ridge Wildlife Management Area
    set_key US-3753 KFF-3753  # Hannahatchee Creek Wildlife Management Area
    set_key US-3754 KFF-3754  # Hart County Wildlife Management Area
    set_key US-3755 KFF-3755  # Horse Creek Wildlife Management Area
    set_key US-3756 KFF-3756  # J.L. Lester Wildlife Management Area
    set_key US-3757 KFF-3757  # Joe Kurz Wildlife Management Area
    set_key US-3758 KFF-3758  # John's Mountain Wildlife Management Area
    set_key US-3759 KFF-3759  # Little Satilla Wildlife Management Area
    set_key US-3760 KFF-3760  # Mayhaw Wildlife Management Area
    set_key US-3761 KFF-3761  # Oaky Woods Wildlife Management Area
    set_key US-3762 KFF-3762  # Ocmulgee Wildlife Management Area
    set_key US-3763 KFF-3763  # Oconee Wildlife Management Area
    set_key US-3764 KFF-3764  # Oliver Bridge Wildlife Management Area
    set_key US-3765 KFF-3765  # Ossabaw Island Heritage Wildlife Management Area
    set_key US-3766 KFF-3766  # Paulks Pasture Wildlife Management Area
    set_key US-3767 KFF-3767  # Penholoway Swamp Wildlife Management Area
    set_key US-3768 KFF-3768  # Phinizy Swamp Wildlife Management Area
    set_key US-3769 KFF-3769  # River Bend Wildlife Management Area
    set_key US-3770 KFF-3770  # River Creek - The Rolf and Alexandra Kauka Wildlife Management Area
    set_key US-3771 KFF-3771  # Rogers Wildlife Management Area
    set_key US-3772 KFF-3772  # Rum Creek Wildlife Management Area
    set_key US-3773 KFF-3773  # Sansavilla Wildlife Management Area
    set_key US-3774 KFF-3774  # Sapelo Island Wildlife Management Area
    set_key US-3775 KFF-3775  # Silver Lake Wildlife Management Area
    set_key US-3776 KFF-3776  # Sprewell Bluff Wildlife Management Area
    set_key US-3777 KFF-3777  # Wilson Shoals Wildlife Management Area
    set_key US-3778 KFF-3778  # Yuchi Wildlife Management Area
    set_key US-3779 KFF-3779  # Big Bone Lick State Historic Site
    set_key US-3781 KFF-3781  # Breaks Interstate State Park
    set_key US-3782 KFF-3782  # Dr. Thomas Walker State Historic Site
    set_key US-3783 KFF-3783  # Jefferson Davis State Historic Site
    set_key US-3784 KFF-3784  # Old Mulkey Meetinghouse State Historic Site
    set_key US-3786 KFF-3786  # Waveland State Historic Site
    set_key US-3790 KFF-3790  # Fort Heiman National Battlefield
    set_key US-3792 KFF-3792  # Land Between the Lakes National Recreation Area
    set_key US-3793 KFF-3793  # Ballard Wildlife Management Area
    set_key US-3794 KFF-3794  # Beaver Creek Wildlife Management Area
    set_key US-3795 KFF-3795  # Beechy Creek Wildlife Management Area
    set_key US-3796 KFF-3796  # Big Rivers Wildlife Management Area
    set_key US-3797 KFF-3797  # Boatwright Wildlife Management Area
    set_key US-3798 KFF-3798  # Buck Creek Wildlife Management Area
    set_key US-3799 KFF-3799  # Burchell-Beech Wildlife Management Area
    set_key US-3800 KFF-3800  # Cedar Creek Lake Wildlife Management Area
    set_key US-3801 KFF-3801  # Clifty Wildlife Management Area
    set_key US-3802 KFF-3802  # Clyde E Buckley Wildlife Management Area
    set_key US-3803 KFF-3803  # Coil Estate Wildlife Management Area
    set_key US-3804 KFF-3804  # Cranks Creek Wildlife Management Area
    set_key US-3805 KFF-3805  # Curtis Gates Lloyd Wildlife Management Area
    set_key US-3806 KFF-3806  # Dennis-Gray Wildlife Management Area
    set_key US-3807 KFF-3807  # Dix River Wildlife Management Area
    set_key US-3808 KFF-3808  # Doug Travis Wildlife Management Area
    set_key US-3809 KFF-3809  # Dr. James R. Rich Wildlife Management Area
    set_key US-3810 KFF-3810  # Dr. Norman And Martha Adair Wildlife Management Area
    set_key US-3811 KFF-3811  # Ed Mabry-Laurel Gorge Wildlife Management Area
    set_key US-3812 KFF-3812  # Fleming Wildlife Management Area
    set_key US-3813 KFF-3813  # Griffith Woods Wildlife Management Area
    set_key US-3814 KFF-3814  # Hensley-Pine Mountain Wildlife Management Area
    set_key US-3815 KFF-3815  # Higginson-Henry Wildlife Management Area
    set_key US-3816 KFF-3816  # John A. Kleber Wildlife Management Area
    set_key US-3817 KFF-3817  # John C. Williams Wildlife Management Area
    set_key US-3818 KFF-3818  # Jones-Keeney Wildlife Management Area
    set_key US-3819 KFF-3819  # Kaler Bottoms Wildlife Management Area
    set_key US-3820 KFF-3820  # Kentucky River Wildlife Management Area
    set_key US-3821 KFF-3821  # L. B. Davison Wildlife Management Area
    set_key US-3822 KFF-3822  # Lee K. Nelson Wildlife Management Area
    set_key US-3823 KFF-3823  # Livingston County Wildlife Management Area
    set_key US-3824 KFF-3824  # Marion County Wildlife Management Area
    set_key US-3825 KFF-3825  # Miller Welch Wildlife Management Area
    set_key US-3826 KFF-3826  # Mullins Wildlife Management Area
    set_key US-3827 KFF-3827  # Obion Creek Wildlife Management Area
    set_key US-3828 KFF-3828  # Peabody Wildlife Management Area
    set_key US-3829 KFF-3829  # R. F. Tarter Wildlife Management Area
    set_key US-3830 KFF-3830  # Sloughs Wildlife Management Area
    set_key US-3831 KFF-3831  # South Shore Wildlife Management Area
    set_key US-3832 KFF-3832  # Stone Mountain Wildlife Management Area
    set_key US-3833 KFF-3833  # T. N. Sullivan Wildlife Management Area
    set_key US-3834 KFF-3834  # Tradewater Wildlife Management Area
    set_key US-3835 KFF-3835  # Twin Eagle Wildlife Management Area
    set_key US-3836 KFF-3836  # Veterans Memorial Wildlife Management Area
    set_key US-3837 KFF-3837  # West Kentucky Wildlife Management Area
    set_key US-3838 KFF-3838  # Winford Wildlife Management Area
    set_key US-3839 KFF-3839  # Yatesville Lake Wildlife Management Area
    set_key US-3840 KFF-3840  # Yellowbank Wildlife Management Area
    set_key US-3841 KFF-3841  # Falls Lake State Recreation Area
    set_key US-3842 KFF-3842  # Fort Fisher State Recreation Area
    set_key US-3843 KFF-3843  # Haw River at Iron Ore Access Belt State Park
    set_key US-3844 KFF-3844  # Jordan Lake State Recreation Area
    set_key US-3845 KFF-3845  # Kerr Lake State Recreation Area
    set_key US-3846 KFF-3846  # Mount Jefferson Natural State Conservation Area
    set_key US-3847 KFF-3847  # Occoneechee Mountain Natural State Conservation Area
    set_key US-3848 KFF-3848  # Weymouth Woods-Sandhills State Nature Preserve
    set_key US-3849 KFF-3849  # Bald Head Woods Reserve State Conservation Area
    set_key US-3850 KFF-3850  # Bird Island Reserve State Conservation Area
    set_key US-3851 KFF-3851  # Brumley Forest State Nature Preserve
    set_key US-3852 KFF-3852  # Buxton Woods State Reserve
    set_key US-3853 KFF-3853  # Emily and Richardson Preyer Buckridge State Reserve
    set_key US-3854 KFF-3854  # Flower Hill State Nature Preserve
    set_key US-3855 KFF-3855  # Great Dismal Swamp National Wildlife Refuge
    set_key US-3856 KFF-3856  # Hoke County Community Forest
    set_key US-3857 KFF-3857  # Horton Grove State Nature Preserve
    set_key US-3859 KFF-3859  # Johnston Mill State Nature Preserve
    set_key US-3860 KFF-3860  # Kitty Hawk Woods State Preserve
    set_key US-3861 KFF-3861  # Little River Natural State Conservation Area
    set_key US-3862 KFF-3862  # Nags Head Woods Ecological State Preserve
    set_key US-3863 KFF-3863  # Palmetto-Peartree State Preserve
    set_key US-3864 KFF-3864  # Permuda Island State Reserve
    set_key US-3865 KFF-3865  # Roanoke Island Marshes State Game Land
    set_key US-3866 KFF-3866  # Selma Cornelison Ward State Nature Preserve
    set_key US-3867 KFF-3867  # Swift Creek Bluffs State Nature Preserve
    set_key US-3868 KFF-3868  # Theodore Roosevelt State Conservation Area
    set_key US-3869 KFF-3869  # Three Top Mountain State Game Land
    set_key US-3870 KFF-3870  # Van Swamp State Game Land
    set_key US-3871 KFF-3871  # White Pines State Nature Preserve
    set_key US-3872 KFF-3872  # Charles Towne Landing State Historic Site
    set_key US-3873 KFF-3873  # Colonial Dorchester State Historic Site
    set_key US-3874 KFF-3874  # H. Cooper Black Jr. Memorial State Recreation Area
    set_key US-3876 KFF-3876  # Hampton Plantation State Historic Site
    set_key US-3877 KFF-3877  # Keowee-Toxaway State Park
    set_key US-3878 KFF-3878  # Lake Greenwood State Park
    set_key US-3879 KFF-3879  # Lake Hartwell State Park
    set_key US-3880 KFF-3880  # Lake Wateree State Park
    set_key US-3881 KFF-3881  # Battle of Musgrove Mill State Historic Site
    set_key US-3882 KFF-3882  # Oconee Station State Historic Site
    set_key US-3883 KFF-3883  # Redcliffe Plantation State Historic Site
    set_key US-3884 KFF-3884  # Battle of Rivers Bridge State Historic Site
    set_key US-3885 KFF-3885  # Rose Hill Plantation State Historic Site
    set_key US-3886 KFF-3886  # Aiken Gopher Tortoise Heritage Preserve Wildlife Management Area
    set_key US-3887 KFF-3887  # Bear Island Wildlife Management Area
    set_key US-3888 KFF-3888  # Bonneau Ferry Wildlife Management Area
    set_key US-3889 KFF-3889  # Botany Bay Plantation Heritage Preserve Wildlife Management Area
    set_key US-3890 KFF-3890  # Buzzard Roost Heritage Preserve Wildlife Management Area
    set_key US-3891 KFF-3891  # Campbells Crossroads and Angelus Tracts Wildlife Management Area
    set_key US-3892 KFF-3892  # Chestnut Ridge Heritage Preserve Wildlife Management Area
    set_key US-3893 KFF-3893  # Cliff Pitts Wildlife Management Area
    set_key US-3894 KFF-3894  # Draper Wildlife Management Area
    set_key US-3895 KFF-3895  # Eastatoe Creek Heritage Preserve Wildlife Management Area
    set_key US-3896 KFF-3896  # Edisto River Wildlife Management Area
    set_key US-3897 KFF-3897  # Fant's Grove Wildlife Management Area
    set_key US-3898 KFF-3898  # Forty Acre Rock Heritage Preserve Wildlife Management Area
    set_key US-3899 KFF-3899  # Great Pee Dee River Heritage Preserve Wildlife Management Area
    set_key US-3900 KFF-3900  # Hamilton Ridge Wildlife Management Area
    set_key US-3901 KFF-3901  # Hickory Top Wildlife Management Area
    set_key US-3902 KFF-3902  # James L. Mason Wildlife Management Area
    set_key US-3903 KFF-3903  # Lewis Ocean Bay Heritage Preserve Wildlife Management Area
    set_key US-3904 KFF-3904  # Longleaf Pine Heritage Preserve Wildlife Management Area
    set_key US-3905 KFF-3905  # Marsh Wildlife Management Area
    set_key US-3906 KFF-3906  # Old Island Heritage Preserve Wildlife Management Area
    set_key US-3907 KFF-3907  # Pee Dee Station Site Wildlife Management Area
    set_key US-3908 KFF-3908  # Samworth Wildlife Management Area
    set_key US-3909 KFF-3909  # Santee Cooper Tract Wildlife Management Area
    set_key US-3910 KFF-3910  # Santee Cooper Wildlife Management Area
    set_key US-3911 KFF-3911  # Stevens Creek Heritage Preserve Wildlife Management Area
    set_key US-3912 KFF-3912  # Thurmond Tract Wildlife Management Area
    set_key US-3913 KFF-3913  # Tillman Sand Ridge Heritage Preserve Wildlife Management Area
    set_key US-3914 KFF-3914  # Cathedral Bay Heritage Preserve State Park
    set_key US-3916 KFF-3916  # Congaree Bluffs Heritage Preserve State Park
    set_key US-3917 KFF-3917  # Little Pee Dee Bay Heritage Preserve State Park
    set_key US-3918 KFF-3918  # Savage Bay Heritage Preserve State Park
    set_key US-3919 KFF-3919  # Congaree Creek Heritage Preserve State Park
    set_key US-3921 KFF-3921  # Pacolet River Heritage Preserve State Park
    set_key US-3922 KFF-3922  # Radnor Lake State Park
    set_key US-3923 KFF-3923  # Bone Cave Natural State Conservation Area
    set_key US-3924 KFF-3924  # Cedars of Lebanon State Forest
    set_key US-3925 KFF-3925  # Vesta Cedar Glade State Natural Area
    set_key US-3926 KFF-3926  # Bean Switch Refuge Wildlife Management Area
    set_key US-3927 KFF-3927  # Bogota Wildlife Management Area
    set_key US-3928 KFF-3928  # Bridgestone/firestone Centennial Wilderness Wildlife Management Area
    set_key US-3929 KFF-3929  # Buffalo Springs Wildlife Management Area
    set_key US-3930 KFF-3930  # Camden Wildlife Management Area
    set_key US-3931 KFF-3931  # Catoosa Wildlife Management Area
    set_key US-3932 KFF-3932  # Cedar Hill Swamp Wildlife Management Area
    set_key US-3933 KFF-3933  # Cheatham Wildlife Management Area
    set_key US-3934 KFF-3934  # Chickasaw State Wildlife Area
    set_key US-3935 KFF-3935  # Chuck Swan Wildlife Management Area
    set_key US-3936 KFF-3936  # Cowan Marsh State Wildlife Area
    set_key US-3937 KFF-3937  # Eagle Lake Refuge Wildlife Management Area
    set_key US-3938 KFF-3938  # Ernest Rice Wildlife Management Area
    set_key US-3939 KFF-3939  # Forks Of The River Wildlife Management Area
    set_key US-3940 KFF-3940  # Gooch Wildlife Management Area
    set_key US-3941 KFF-3941  # Grundy Forest State Natural Area
    set_key US-3942 KFF-3942  # Haley-jaqueth Wildlife Management Area
    set_key US-3943 KFF-3943  # Haynes Bottom Wildlife Management Area
    set_key US-3944 KFF-3944  # Hickory Flats Wildlife Management Area
    set_key US-3945 KFF-3945  # Hop-in Wildlife Refuge
    set_key US-3946 KFF-3946  # Horns Bluff Refuge Wildlife Management Area
    set_key US-3947 KFF-3947  # Jackson Swamp Wildlife Management Area
    set_key US-3948 KFF-3948  # John Tully Wildlife Management Area
    set_key US-3949 KFF-3949  # Kyker Bottoms Wildlife Refuge
    set_key US-3950 KFF-3950  # Lauderdale Waterfowl Wildlife Management Area
    set_key US-3951 KFF-3951  # Laurel Hill Wildlife Management Area
    set_key US-3952 KFF-3952  # M.T.S.U. Wildlife Management Area
    set_key US-3953 KFF-3953  # Maness Swamp State Wildlife Area
    set_key US-3954 KFF-3954  # Mingo Swamp Wildlife Management Area
    set_key US-3955 KFF-3955  # Moss Island Wildlife Management Area
    set_key US-3956 KFF-3956  # Murfree Springs State Wildlife Area
    set_key US-3957 KFF-3957  # Natchez Trace State Forest Wildlife Management Area
    set_key US-3958 KFF-3958  # North Chickamauga Creek Wildlife Management Area
    set_key US-3959 KFF-3959  # Obion River Wildlife Management Area
    set_key US-3960 KFF-3960  # Reelfoot State Wildlife Area
    set_key US-3961 KFF-3961  # South Fork Waterfowl National Wildlife Refuge
    set_key US-3962 KFF-3962  # The Boils State Wildlife Area
    set_key US-3963 KFF-3963  # Three Rivers Wildlife Management Area
    set_key US-3964 KFF-3964  # Tumbleweed Wildlife Management Area
    set_key US-3965 KFF-3965  # White Lake Wildlife Refuge
    set_key US-3966 KFF-3966  # White Oak Wildlife Management Area
    set_key US-3967 KFF-3967  # Whites Mill Wildlife Refuge
    set_key US-3968 KFF-3968  # Williamsport Wildlife Management Area
    set_key US-3969 KFF-3969  # Wolf River Wildlife Management Area
    set_key US-3970 KFF-3970  # Yanahli Wildlife Management Area
    set_key US-3971 KFF-3971  # Prentice Cooper Wildlife Management Area
    set_key US-3972 KFF-3972  # Natural Bridge State Park
    set_key US-3973 KFF-3973  # Amelia Wildlife Management Area
    set_key US-3974 KFF-3974  # Briery Creek Wildlife Management Area
    set_key US-3975 KFF-3975  # C.F. Phelps Wildlife Management Area
    set_key US-3976 KFF-3976  # Cavalier Wildlife Management Area
    set_key US-3977 KFF-3977  # Chickahominy Wildlife Management Area
    set_key US-3978 KFF-3978  # Clinch Mountain Wildlife Management Area
    set_key US-3979 KFF-3979  # Crooked Creek Wildlife Management Area
    set_key US-3980 KFF-3980  # Dick Cross Wildlife Management Area
    set_key US-3981 KFF-3981  # Fairystone Farms Wildlife Management Area
    set_key US-3982 KFF-3982  # Featherfin Wildlife Management Area
    set_key US-3983 KFF-3983  # Game Farm Marsh Wildlife Management Area
    set_key US-3984 KFF-3984  # Goshen and Little North Mountain Wildlife Management Area
    set_key US-3985 KFF-3985  # Hardware River Wildlife Management Area
    set_key US-3986 KFF-3986  # Havens Wildlife Management Area
    set_key US-3987 KFF-3987  # Hidden Valley Wildlife Management Area
    set_key US-3988 KFF-3988  # Highland Wildlife Management Area
    set_key US-3989 KFF-3989  # Hog Island Wildlife Management Area
    set_key US-3990 KFF-3990  # Horsepen Lake Wildlife Management Area
    set_key US-3991 KFF-3991  # James River Wildlife Management Area
    set_key US-3992 KFF-3992  # Land's End Wildlife Management Area
    set_key US-3993 KFF-3993  # Merrimac Farm Wildlife Management Area
    set_key US-3994 KFF-3994  # Mockhorn Island Wildlife Management Area
    set_key US-3995 KFF-3995  # Pettigrew Wildlife Management Area
    set_key US-3996 KFF-3996  # Powhatan Wildlife Management Area
    set_key US-3997 KFF-3997  # Princess Anne Wildlife Management Area
    set_key US-3998 KFF-3998  # Ragged Island Wildlife Management Area
    set_key US-3999 KFF-3999  # Rapidan Wildlife Management Area
    set_key US-4000 KFF-4000  # Saxis Wildlife Management Area
    set_key US-4001 KFF-4001  # Stewarts Creek Wildlife Management Area
    set_key US-4002 KFF-4002  # Turkeycock Wildlife Management Area
    set_key US-4003 KFF-4003  # Weston Wildlife Management Area
    set_key US-4004 KFF-4004  # White Oak Mountain Wildlife Management Area
    set_key US-4005 KFF-4005  # Big Survey Wildlife Management Area
    set_key US-4006 KFF-4006  # Gathright Wildlife Management Area
    set_key US-4007 KFF-4007  # Short Hills Wildlife Management Area
    set_key US-4008 KFF-4008  # Thompson Wildlife Management Area
    set_key US-4009 KFF-4009  # Ozark National Wild and Scenic River
    set_key US-4010 KFF-4010  # Heron Haven State Park
    set_key US-4011 KFF-4011  # Chalco Hills State Recreation Area
    set_key US-4012 KFF-4012  # Elkhorn Crossing State Park
    set_key US-4013 KFF-4013  # Prairie View State Recreation Area
    set_key US-4014 KFF-4014  # Prairie Queen State Recreation Area
    set_key US-4015 KFF-4015  # Platte River Landing State Park
    set_key US-4016 KFF-4016  # Cottontail Wildlife Management Area
    set_key US-4017 KFF-4017  # Lincoln Saline Wetland State Park
    set_key US-4018 KFF-4018  # Wildwood Lake Wildlife Management Area
    set_key US-4019 KFF-4019  # Wild Plum Wildlife Management Area
    set_key US-4020 KFF-4020  # Timber Point Wildlife Management Area
    set_key US-4021 KFF-4021  # Red Cedar Wildlife Management Area
    set_key US-4022 KFF-4022  # Merganser Wildlife Management Area
    set_key US-4023 KFF-4023  # Chalkrock Wildlife Management Area
    set_key US-4024 KFF-4024  # Bruning Dam Wildlife Management Area
    set_key US-4025 KFF-4025  # Buckley Creek State Recreation Area
    set_key US-4026 KFF-4026  # Liberty Cove State Recreation Area
    set_key US-4027 KFF-4027  # Lone Star State Recreation Area
    set_key US-4028 KFF-4028  # Prairie Lake State Recreation Area
    set_key US-4029 KFF-4029  # Roseland Lake State Recreation Area
    set_key US-4030 KFF-4030  # Bear Creek Wildlife Management Area
    set_key US-4031 KFF-4031  # Big Indian State Recreation Area
    set_key US-4032 KFF-4032  # Clatonia State Recreation Area
    set_key US-4033 KFF-4033  # Cub Creek State Recreation Area
    set_key US-4034 KFF-4034  # Leisure Lake Wildlife Management Area
    set_key US-4035 KFF-4035  # Swanton Wildlife Management Area
    set_key US-4036 KFF-4036  # Walnut Creek State Recreation Area
    set_key US-4037 KFF-4037  # Willard L. Meyer State Recreation Area
    set_key US-4038 KFF-4038  # Wolf-Wildcat Wildlife Management Area
    set_key US-4039 KFF-4039  # Maple Creek State Recreation Area
    set_key US-4040 KFF-4040  # Maskenthine Lake State Recreation Area
    set_key US-4041 KFF-4041  # Pilger State Recreation Area
    set_key US-4042 KFF-4042  # Alexander Forest Wildlife Management Area
    set_key US-4043 KFF-4043  # Atchafalaya Delta Wildlife Management Area
    set_key US-4044 KFF-4044  # Attakapas Island Wildlife Management Area
    set_key US-4045 KFF-4045  # Bayou Macon Wildlife Management Area
    set_key US-4046 KFF-4046  # Bayou Pierre Wildlife Management Area
    set_key US-4047 KFF-4047  # Ben Lilly State Fish and Wildlife Area
    set_key US-4048 KFF-4048  # Big Colewa Bayou Wildlife Management Area
    set_key US-4049 KFF-4049  # Big Lake Wildlife Management Area
    set_key US-4050 KFF-4050  # Biloxi Wildlife Management Area
    set_key US-4051 KFF-4051  # Bodcau Wildlife Management Area
    set_key US-4052 KFF-4052  # Boeuf Wildlife Management Area
    set_key US-4053 KFF-4053  # Buckhorn Wildlife Management Area
    set_key US-4054 KFF-4054  # Catahoula Lake Wildlife Management Area
    set_key US-4055 KFF-4055  # Clear Creek Wildlife Management Area
    set_key US-4056 KFF-4056  # Dewey Wills Wildlife Management Area
    set_key US-4057 KFF-4057  # Elbow Slough Wildlife Management Area
    set_key US-4058 KFF-4058  # Elm Hall Wildlife Management Area
    set_key US-4059 KFF-4059  # Grassy Lake Wildlife Management Area
    set_key US-4060 KFF-4060  # Hutchinson Creek Wildlife Management Area
    set_key US-4061 KFF-4061  # J. C. 'Sonny' Gilbert Wildlife Management Area
    set_key US-4062 KFF-4062  # Joyce Wildlife Management Area
    set_key US-4063 KFF-4063  # Lake Boeuf Wildlife Management Area
    set_key US-4064 KFF-4064  # Lake Ramsey Savannah Wildlife Management Area
    set_key US-4065 KFF-4065  # Little River Wildlife Management Area
    set_key US-4066 KFF-4066  # Loggy Bayou Wildlife Management Area
    set_key US-4067 KFF-4067  # Manchac Wildlife Management Area
    set_key US-4068 KFF-4068  # Marsh Bayou Wildlife Management Area
    set_key US-4069 KFF-4069  # Maurepas Swamp Wildlife Management Area
    set_key US-4070 KFF-4070  # Pass-a-Loutre Wildlife Management Area
    set_key US-4071 KFF-4071  # Pearl River Wildlife Management Area
    set_key US-4072 KFF-4072  # Peason Ridge Wildlife Management Area
    set_key US-4073 KFF-4073  # Pointe-aux-Chenes Wildlife Management Area
    set_key US-4074 KFF-4074  # Pomme de Terre Wildlife Management Area
    set_key US-4075 KFF-4075  # Richard K. Yancey Wildlife Management Area
    set_key US-4076 KFF-4076  # Russell Sage Wildlife Management Area
    set_key US-4077 KFF-4077  # Sabine Island Wildlife Management Area
    set_key US-4078 KFF-4078  # Sabine Wildlife Management Area
    set_key US-4079 KFF-4079  # Salvador Wildlife Management Area
    set_key US-4080 KFF-4080  # Timken Wildlife Management Area
    set_key US-4081 KFF-4081  # Sandy Hollow Wildlife Management Area
    set_key US-4082 KFF-4082  # Sherburne Wildlife Management Area
    set_key US-4083 KFF-4083  # Soda Lake Wildlife Management Area
    set_key US-4084 KFF-4084  # Spring Bayou Wildlife Management Area
    set_key US-4085 KFF-4085  # Tangipahoa Parish School Board Wildlife Management Area
    set_key US-4086 KFF-4086  # Thistlethwaite Wildlife Management Area
    set_key US-4087 KFF-4087  # Tunica Hills Wildlife Management Area
    set_key US-4088 KFF-4088  # Walnut Hill Wildlife Management Area
    set_key US-4089 KFF-4089  # West Bay Wildlife Management Area
    set_key US-4091 KFF-4091  # Great River National Wildlife Refuge
    set_key US-4092 KFF-4092  # Salem Unit of Apple River Canyon State Park
    set_key US-4093 KFF-4093  # Clinton Lake State Recreation Area
    set_key US-4094 KFF-4094  # Eagle Creek State Park
    set_key US-4095 KFF-4095  # Frank Holten State Recreation Area
    set_key US-4096 KFF-4096  # Golconda Marina State Recreation Area
    set_key US-4097 KFF-4097  # Kickapoo State Recreation Area
    set_key US-4098 KFF-4098  # Lincoln Trail Homestead State Park
    set_key US-4099 KFF-4099  # Moraine View State Recreation Area
    set_key US-4100 KFF-4100  # Prophetstown State Park
    set_key US-4101 KFF-4101  # Pyramid State Park
    set_key US-4102 KFF-4102  # Randolph County State Recreation Area
    set_key US-4103 KFF-4103  # Shabbona Lake State Recreation Area
    set_key US-4104 KFF-4104  # Stephen A. Forbes State Recreation Area
    set_key US-4105 KFF-4105  # Washington County State Recreation Area
    set_key US-4106 KFF-4106  # Weinberg-King State Park
    set_key US-4107 KFF-4107  # William W. Powers State Recreation Area
    set_key US-4108 KFF-4108  # Banner Marsh State Fish and Wildlife Area
    set_key US-4109 KFF-4109  # Big Bend State Fish and Wildlife Area
    set_key US-4110 KFF-4110  # Big River State Forest
    set_key US-4111 KFF-4111  # Bohm Woods State Nature Preserve
    set_key US-4112 KFF-4112  # Cache River State Natural Area
    set_key US-4113 KFF-4113  # Cape Bend State Fish and Wildlife Area
    set_key US-4114 KFF-4114  # Carlyle Lake State Fish and Wildlife Area
    set_key US-4115 KFF-4115  # Cedar Glen State Natural Area
    set_key US-4116 KFF-4116  # Chouteau Island State Fish and Wildlife Area
    set_key US-4117 KFF-4117  # Coffeen Lake State Fish and Wildlife Area
    set_key US-4118 KFF-4118  # Copperhead Hollow State Wildlife Area
    set_key US-4119 KFF-4119  # Crawford County State Fish and Wildlife Area
    set_key US-4120 KFF-4120  # Des Plaines State Fish and Wildlife Area
    set_key US-4121 KFF-4121  # Devil's Island Wildlife Management Area
    set_key US-4122 KFF-4122  # Fall Creek Overlook State Natural Area
    set_key US-4123 KFF-4123  # Franklin Creek State Natural Area
    set_key US-4124 KFF-4124  # Fults Hill Prairie State Nature Preserve
    set_key US-4125 KFF-4125  # Goode's Woods State Nature Preserve
    set_key US-4126 KFF-4126  # Green River State Wildlife Area
    set_key US-4127 KFF-4127  # Harry 'Babe' Woodyard State Natural Area
    set_key US-4128 KFF-4128  # Henderson County State Fish and Wildlife Area
    set_key US-4129 KFF-4129  # Hidden Springs State Forest
    set_key US-4130 KFF-4130  # Horseshoe Lake-Alexander State Fish and Wildlife Area
    set_key US-4131 KFF-4131  # Illinois Caverns State Natural Area
    set_key US-4132 KFF-4132  # Iroquois County State Wildlife Area
    set_key US-4133 KFF-4133  # Jim Edgar Panther Creek State Fish and Wildlife Area
    set_key US-4134 KFF-4134  # Kaskaskia River State Fish and Wildlife Area
    set_key US-4135 KFF-4135  # Kidd Lake Marsh State Natural Area
    set_key US-4136 KFF-4136  # Kinkaid Lake State Fish and Wildlife Area
    set_key US-4137 KFF-4137  # Lowden-Miller State Forest
    set_key US-4139 KFF-4139  # Marseilles State Fish and Wildlife Area
    set_key US-4140 KFF-4140  # Marshall State Fish and Wildlife Area
    set_key US-4141 KFF-4141  # Mautino State Fish and Wildlife Area
    set_key US-4142 KFF-4142  # Mazonia-Braidwood State Fish and Wildlife Area
    set_key US-4143 KFF-4143  # Mermet Lake State Fish and Wildlife Area
    set_key US-4144 KFF-4144  # Middle Fork State Fish and Wildlife Area
    set_key US-4145 KFF-4145  # Miller-Anderson Woods State Nature Preserve
    set_key US-4146 KFF-4146  # Mississippi River State Fish and Wildlife Area
    set_key US-4147 KFF-4147  # Newton Lake State Fish and Wildlife Area
    set_key US-4148 KFF-4148  # Peabody River King State Fish and Wildlife Area
    set_key US-4149 KFF-4149  # Piney Creek Ravine State Natural Area
    set_key US-4150 KFF-4150  # Ray Norbut State Fish and Wildlife Area
    set_key US-4151 KFF-4151  # Sand Ridge State Forest
    set_key US-4152 KFF-4152  # Sanganois State Fish and Wildlife Area
    set_key US-4153 KFF-4153  # Kaskaskia unit of Shelbyville State Fish and Wildlife Area
    set_key US-4154 KFF-4154  # West Okaw unit of Shelbyville State Fish and Wildlife Area
    set_key US-4155 KFF-4155  # Sielbeck Forest State Natural Area
    set_key US-4156 KFF-4156  # Ten Mile Creek State Fish and Wildlife Area
    set_key US-4157 KFF-4157  # Trail of Tears State Forest
    set_key US-4158 KFF-4158  # Turkey Bluffs State Fish and Wildlife Area
    set_key US-4159 KFF-4159  # Union County State Fish and Wildlife Area
    set_key US-4160 KFF-4160  # Volo Bog State Natural Area
    set_key US-4161 KFF-4161  # Quakertown on Brookville Lake State Recreation Area
    set_key US-4162 KFF-4162  # Mounds on Brookville Lake State Recreation Area
    set_key US-4163 KFF-4163  # Cagles Mill Lake State Recreation Area
    set_key US-4164 KFF-4164  # Cecil M. Harden Lake State Recreation Area
    set_key US-4165 KFF-4165  # Deam Lake State Recreation Area
    set_key US-4166 KFF-4166  # Hardy Lake State Recreation Area
    set_key US-4167 KFF-4167  # Interlake State Recreation Area
    set_key US-4168 KFF-4168  # Frances Slocum on Mississinewa Lake State Recreation Area
    set_key US-4169 KFF-4169  # Miami on Mississinewa Lake State Recreation Area
    set_key US-4170 KFF-4170  # Hardin Ridge on Monroe Lake State Recreation Area
    set_key US-4171 KFF-4171  # Paynetown on Monroe Lake State Recreation Area
    set_key US-4172 KFF-4172  # Jackson on Patoka Lake State Recreation Area
    set_key US-4173 KFF-4173  # Lick Fork on Patoka Lake State Recreation Area
    set_key US-4174 KFF-4174  # Newton Steward on Patoka Lake State Recreation Area
    set_key US-4175 KFF-4175  # Tillery Hill on Patoka Lake State Recreation Area
    set_key US-4176 KFF-4176  # Redbird State Recreation Area
    set_key US-4177 KFF-4177  # Dora-New Holland on Salamonie Lake State Recreation Area
    set_key US-4178 KFF-4178  # Lost Bridge on Salamonie Lake State Recreation Area
    set_key US-4179 KFF-4179  # Mt Etna on Salamonie Lake State Recreation Area
    set_key US-4180 KFF-4180  # Mt Hope on Salamonie Lake State Recreation Area
    set_key US-4181 KFF-4181  # Starve Hollow State Recreation Area
    set_key US-4182 KFF-4182  # Trine at Pokagon State Recreation Area
    set_key US-4183 KFF-4183  # Atterbury State Fish and Wildlife Area
    set_key US-4184 KFF-4184  # Baltzell-Lenhart Woods State Nature Preserve
    set_key US-4185 KFF-4185  # Berns-Meyer State Nature Preserve
    set_key US-4186 KFF-4186  # Big Walnut - Tall Timbers Trail State Nature Preserve
    set_key US-4187 KFF-4187  # Blue Grass State Fish and Wildlife Area
    set_key US-4188 KFF-4188  # Bryan Woods State Nature Preserve
    set_key US-4189 KFF-4189  # Chamberlain Lake State Nature Preserve
    set_key US-4190 KFF-4190  # Chinook State Fish and Wildlife Area
    set_key US-4191 KFF-4191  # Clark State Forest
    set_key US-4192 KFF-4192  # Crooked Lake State Nature Preserve
    set_key US-4193 KFF-4193  # Crosley State Fish and Wildlife Area
    set_key US-4194 KFF-4194  # Deer Creek State Fish and Wildlife Area
    set_key US-4195 KFF-4195  # Dunes State Nature Preserve
    set_key US-4196 KFF-4196  # Dunes Prairie State Nature Preserve
    set_key US-4197 KFF-4197  # Fairbanks Landing State Fish and Wildlife Area
    set_key US-4198 KFF-4198  # Ferdinand State Forest
    set_key US-4199 KFF-4199  # Glendale State Fish and Wildlife Area
    set_key US-4200 KFF-4200  # Goose Pond State Fish and Wildlife Area
    set_key US-4201 KFF-4201  # Greene-Sullivan State Forest
    set_key US-4202 KFF-4202  # Hall Woods State Nature Preserve
    set_key US-4203 KFF-4203  # Harrison-Crawford State Forest
    set_key US-4204 KFF-4204  # Hemlock Bluff State Nature Preserve
    set_key US-4205 KFF-4205  # Hillenbrand State Fish and Wildlife Area
    set_key US-4206 KFF-4206  # Hoosier Prairie State Nature Preserve
    set_key US-4207 KFF-4207  # Hovey Lake State Fish and Wildlife Area
    set_key US-4208 KFF-4208  # J. E. Roush Lake State Fish and Wildlife Area
    set_key US-4209 KFF-4209  # Jackson-Washington State Forest
    set_key US-4210 KFF-4210  # Jasper-Pulaski State Fish and Wildlife Area
    set_key US-4211 KFF-4211  # Kankakee State Fish and Wildlife Area
    set_key US-4212 KFF-4212  # Kingsbury State Fish and Wildlife Area
    set_key US-4213 KFF-4213  # LaSalle State Fish and Wildlife Area
    set_key US-4214 KFF-4214  # Martin State Forest
    set_key US-4215 KFF-4215  # Morgan-Monroe State Forest
    set_key US-4216 KFF-4216  # Olin Lake State Nature Preserve
    set_key US-4217 KFF-4217  # Owen-Putnam State Forest
    set_key US-4218 KFF-4218  # Pigeon River State Fish and Wildlife Area
    set_key US-4219 KFF-4219  # Pike State Forest
    set_key US-4220 KFF-4220  # Pipewort Pond Lieber Memorial State Nature Preserve
    set_key US-4221 KFF-4221  # Pisgah Marsh Area State Fish and Wildlife Area
    set_key US-4222 KFF-4222  # Portland Arch State Nature Preserve
    set_key US-4223 KFF-4223  # Reynolds Creek State Fish and Wildlife Area
    set_key US-4224 KFF-4224  # Salamonie River and Frances Slocum State Forest
    set_key US-4225 KFF-4225  # Selmier State Forest
    set_key US-4226 KFF-4226  # Shrader-Weaver State Nature Preserve
    set_key US-4227 KFF-4227  # Splinter Ridge State Fish and Wildlife Area
    set_key US-4228 KFF-4228  # Sugar Ridge State Fish and Wildlife Area
    set_key US-4229 KFF-4229  # Tri-County State Fish and Wildlife Area
    set_key US-4230 KFF-4230  # Twin Swamps State Nature Preserve
    set_key US-4231 KFF-4231  # Wabashiki State Fish and Wildlife Area
    set_key US-4232 KFF-4232  # Wilbur Wright State Fish and Wildlife Area
    set_key US-4233 KFF-4233  # Willow Slough State Fish and Wildlife Area
    set_key US-4234 KFF-4234  # Winamac State Fish and Wildlife Area
    set_key US-4235 KFF-4235  # Yellowwood State Forest
    set_key US-4236 NIL-0000  # Upper Mississippi River National Wildlife Refuge (IA); WWFF candidates: KFF-0372, KFF-4090, KFF-4236, KFF-4626
    set_key US-4238 KFF-4238  # Ice Age Trail National Scenic Trail
    set_key US-4239 NIL-0000  # North Country Trail National Scenic Trail (VT); WWFF candidates: KFF-4239, KFF-5028, KFF-5029, KFF-5030, KFF-5031, KFF-5032, KFF-5033, KFF-6573
    set_key US-4242 KFF-4242  # Fenley State Recreation Area
    set_key US-4243 KFF-4243  # Sauk Prairie State Recreation Area
    set_key US-4244 KFF-4244  # Big Bay Sand Spit and Bog State Natural Area
    set_key US-4245 KFF-4245  # Two Creeks Buried Forest State Natural Area
    set_key US-4246 KFF-4246  # Whitefish Dunes State Natural Area
    set_key US-4247 KFF-4247  # Heritage Hill State Park
    set_key US-4248 KFF-4248  # Lost Dauphin State Park
    set_key US-4249 KFF-4249  # WI Interstate State Park
    set_key US-4250 KFF-4250  # Capitol Springs State Recreation Area
    set_key US-4251 KFF-4251  # Bibon Swamp State Natural Area
    set_key US-4252 KFF-4252  # Brule Glacial Spillway State Natural Area
    set_key US-4253 KFF-4253  # Cedarburg Bog State Natural Area
    set_key US-4254 KFF-4254  # Chimney Rock Oak Savanna State Natural Area
    set_key US-4255 KFF-4304  # Lodi Marsh State Natural Area
    set_key US-4256 KFF-4256  # Cadiz Springs State Recreation Area
    set_key US-4257 KFF-4257  # Chippewa Moraine Ice Age State Recreation Area
    set_key US-4258 KFF-4258  # Fischer Creek State Recreation Area
    set_key US-4259 KFF-4259  # Hoffman Hills State Recreation Area
    set_key US-4260 KFF-4260  # Long Lake State Recreation Area
    set_key US-4261 KFF-4261  # Mauthe Lake State Recreation Area
    set_key US-4262 KFF-4262  # Pemene Falls Unit of Menominee River State Recreation Area
    set_key US-4263 KFF-4263  # Piers Gorge Unit of Menominee River State Recreation Area
    set_key US-4264 KFF-4264  # Quiver Falls Unit of Menominee River State Recreation Area
    set_key US-4265 KFF-4265  # Richard Bong State Recreation Area
    set_key US-4266 KFF-4266  # Ackley State Wildlife Area
    set_key US-4267 KFF-4267  # Amberg State Wildlife Area
    set_key US-4268 KFF-4268  # Amsterdam Sloughs State Wildlife Area
    set_key US-4269 KFF-4269  # Augusta State Wildlife Area
    set_key US-4270 KFF-4270  # Balsam Branch State Wildlife Area
    set_key US-4271 KFF-4271  # Beaver Brook State Wildlife Area
    set_key US-4272 KFF-4272  # Bill Cross State Wildlife Area
    set_key US-4273 KFF-4273  # Borst Valley State Wildlife Area
    set_key US-4274 KFF-4274  # Brillion State Wildlife Area
    set_key US-4275 KFF-4275  # Chief River State Wildlife Area
    set_key US-4276 KFF-4276  # Chimney Rock State Wildlife Area
    set_key US-4277 KFF-4277  # Collins Marsh State Wildlife Area
    set_key US-4278 KFF-4278  # Crex Meadows State Wildlife Area
    set_key US-4279 KFF-4279  # Cylon State Wildlife Area
    set_key US-4280 KFF-4280  # Deer Creek State Wildlife Area
    set_key US-4281 KFF-4281  # Dell Creek State Wildlife Area
    set_key US-4282 KFF-4282  # Douglas County State Wildlife Area
    set_key US-4283 KFF-4283  # Dunnville State Wildlife Area
    set_key US-4284 KFF-4284  # Eldorado State Wildlife Area
    set_key US-4285 KFF-4285  # Fish Lake State Wildlife Area
    set_key US-4286 KFF-4286  # French Creek State Wildlife Area
    set_key US-4287 KFF-4287  # Gardner Swamp State Wildlife Area
    set_key US-4288 KFF-4288  # Germania Marsh State Wildlife Area
    set_key US-4289 KFF-4289  # Goose Lake State Wildlife Area
    set_key US-4290 KFF-4290  # Grand River Marsh State Wildlife Area
    set_key US-4291 KFF-4291  # Peshtigo Harbor Unit of Green Bay West Shore State Wildlife Area
    set_key US-4292 KFF-4292  # Hay Creek-Hoffman Lake State Wildlife Area
    set_key US-4293 KFF-4293  # Holland State Wildlife Area
    set_key US-4294 KFF-4294  # Horicon Marsh State Wildlife Area
    set_key US-4295 KFF-4295  # Joel Marsh State Wildlife Area
    set_key US-4296 KFF-4296  # Bell Center Unit of Kickapoo River State Wildlife Area
    set_key US-4297 KFF-4297  # Kiel Marsh State Wildlife Area
    set_key US-4298 KFF-4298  # Killsnake State Wildlife Area
    set_key US-4299 KFF-4299  # Kimberly Clark State Wildlife Area
    set_key US-4300 KFF-4300  # Kissick Swamp State Wildlife Area
    set_key US-4301 KFF-4301  # Lake Noquebay State Wildlife Area
    set_key US-4302 KFF-4302  # Lawrence Creek Fish State Wildlife Area
    set_key US-4303 KFF-4303  # Little Rice State Wildlife Area
    set_key US-4304 KFF-4255  # Lodi Marsh State Wildlife Area
    set_key US-4305 KFF-4305  # Loon Lake State Wildlife Area
    set_key US-4306 KFF-4306  # Mack State Wildlife Area
    set_key US-4307 KFF-4307  # Maine State Wildlife Area
    set_key US-4308 KFF-4308  # McKenzie Creek State Wildlife Area
    set_key US-4309 KFF-4309  # McMillan Marsh State Wildlife Area
    set_key US-4310 KFF-4310  # Mead State Wildlife Area
    set_key US-4311 KFF-4311  # Meadow Valley State Wildlife Area
    set_key US-4312 KFF-4312  # Mud Lake State Wildlife Area
    set_key US-4313 KFF-4313  # Muddy Creek State Wildlife Area
    set_key US-4314 KFF-4314  # Mukwa State Wildlife Area
    set_key US-4315 KFF-4315  # Mullet Creek State Wildlife Area
    set_key US-4316 KFF-4316  # Navarino State Wildlife Area
    set_key US-4317 KFF-4317  # New Auburn State Wildlife Area
    set_key US-4318 KFF-4318  # New Wood State Wildlife Area
    set_key US-4319 KFF-4319  # Pershing State Wildlife Area
    set_key US-4320 KFF-4320  # Peshtigo Brook State Wildlife Area
    set_key US-4321 KFF-4321  # Peters Marsh State Wildlife Area
    set_key US-4322 KFF-4322  # Pine Island State Wildlife Area
    set_key US-4323 KFF-4323  # Potato Creek State Wildlife Area
    set_key US-4324 KFF-4324  # Powell Marsh State Wildlife Area
    set_key US-4325 KFF-4325  # Poygan Marsh State Wildlife Area
    set_key US-4326 KFF-4326  # Rat River State Wildlife Area
    set_key US-4327 KFF-4327  # Rice Beds Creek State Wildlife Area
    set_key US-4328 KFF-4328  # Sandhill State Wildlife Area
    set_key US-4329 KFF-4329  # Sheboygan Marsh State Wildlife Area
    set_key US-4330 KFF-4330  # Spring Creek State Wildlife Area
    set_key US-4331 KFF-4331  # Swan Lake State Wildlife Area
    set_key US-4332 KFF-4332  # Theresa Marsh State Wildlife Area
    set_key US-4333 KFF-4333  # Thunder Lake State Wildlife Area
    set_key US-4334 KFF-4334  # Tom Lawin State Wildlife Area
    set_key US-4335 KFF-4335  # Totagatic Lake State Wildlife Area
    set_key US-4336 KFF-4336  # Totogatic State Wildlife Area
    set_key US-4337 KFF-4337  # Underwood State Wildlife Area
    set_key US-4338 KFF-4338  # Washington Creek State Wildlife Area
    set_key US-4339 KFF-4339  # Waunakee Marsh State Wildlife Area
    set_key US-4340 KFF-4340  # Weirgor Springs State Wildlife Area
    set_key US-4341 KFF-4341  # White River Marsh State Wildlife Area
    set_key US-4342 KFF-4342  # Herb Behnke Unit of Wolf River Bottoms State Wildlife Area
    set_key US-4343 KFF-4343  # LaSage Unit of Wolf River Bottoms State Wildlife Area
    set_key US-4344 KFF-4344  # Wolf River State Wildlife Area
    set_key US-4345 KFF-4345  # Woodboro Lakes State Wildlife Area
    set_key US-4346 KFF-4346  # Yellow River State Wildlife Area
    set_key US-4347 KFF-4347  # Yellowstone State Wildlife Area
    set_key US-4348 KFF-4348  # Black River State Forest
    set_key US-4349 KFF-4349  # Flambeau River State Forest
    set_key US-4350 KFF-4350  # Governor Knowles State Forest
    set_key US-4352 KFF-4352  # Northern Unit of Kettle Moraine State Forest
    set_key US-4354 KFF-4354  # Point Beach State Forest
    set_key US-4355 KFF-4355  # Big Spring State Park
    set_key US-4356 KFF-4356  # Boyd Big Tree State Preserve
    set_key US-4357 KFF-4357  # Bucktail State Park
    set_key US-4358 KFF-4358  # Jacobsburg State Park
    set_key US-4359 KFF-4359  # Jennings Environmental State Park
    set_key US-4360 KFF-4360  # Joseph E. Ibberson State Fish and Wildlife Area
    set_key US-4361 KFF-4361  # King's Gap State Park
    set_key US-4362 KFF-4362  # Nolde Forest Environmental State Park
    set_key US-4363 KFF-4363  # Norristown Farm State Park
    set_key US-4364 KFF-4364  # Varden State Fish and Wildlife Area
    set_key US-4365 KFF-4365  # North Point Battlefield State Park
    set_key US-4366 KFF-4366  # Auburn Valley State Park
    set_key US-4367 KFF-4367  # First State Heritage State Park
    set_key US-4368 KFF-4368  # Wachusett Mountain Reservation State Park
    set_key US-4369 KFF-4369  # Shenipsit State Forest
    set_key US-4370 KFF-4370  # Caddo National Grasslands Wildlife Management Area
    set_key US-4371 KFF-4371  # Lyndon B. Johnson National Grassland
    set_key US-4372 KFF-4372  # Pleasant Creek State Recreation Area
    set_key US-4373 KFF-4373  # Blue Mountain Lake (Outlet Area and Waveland Park) National Recreation Area
    set_key US-4374 KFF-4374  # Robert Moses (Thousand Islands) State Park
    set_key US-4377 KFF-4377  # Mines of Spain State Recreation Area
    set_key US-4378 KFF-4378  # Deschutes National Forest
    set_key US-4379 NIL-0000  # Winema National Forest; WWFF candidates: KFF-4379, KFF-4646
    set_key US-4380 KFF-4380  # Malheur National Forest
    set_key US-4381 KFF-4381  # Mount Hood National Forest
    set_key US-4382 KFF-4382  # Ochoco National Forest
    set_key US-4383 NIL-0000  # Rogue River National Forest (CA); WWFF candidates: KFF-4383, KFF-4628, KFF-4629, KFF-4630
    set_key US-4384 KFF-4384  # Siuslaw National Forest
    set_key US-4385 NIL-0000  # Umatilla National Forest (WA); WWFF candidates: KFF-4385, KFF-4597
    set_key US-4386 KFF-4386  # Umpqua National Forest
    set_key US-4387 NIL-0000  # Whitman National Forest (OR); WWFF candidates: KFF-4387, KFF-4631, KFF-4632
    set_key US-4388 KFF-4388  # Willamette National Forest
    set_key US-4389 KFF-4389  # Cascade-Siskiyou National Monument
    set_key US-4390 KFF-4390  # Newberry Crater Volcanic National Monument
    set_key US-4391 NIL-0000  # Toiyabe National Forest (CA); WWFF candidates: KFF-4391, KFF-4633, KFF-4634
    set_key US-4392 KFF-4392  # Basin and Range National Monument
    set_key US-4393 KFF-4393  # Gold Butte National Monument
    set_key US-4394 NIL-0000  # Ashley National Forest (WY); WWFF candidates: KFF-4394, KFF-4600
    set_key US-4395 KFF-4395  # Dixie National Forest
    set_key US-4396 KFF-4396  # Fishlake National Forest
    set_key US-4397 KFF-4397  # Manti-La Sal National Forest (UT)
    set_key US-4398 NIL-0000  # Cache National Forest (UT); WWFF candidates: KFF-4398, KFF-4637, KFF-4638, KFF-4639
    set_key US-4399 KFF-4399  # Grand Staircase-Escalante BLM National Monument
    set_key US-4400 KFF-4400  # Arapaho National Forest
    set_key US-4401 KFF-4401  # Grand Mesa National Forest
    set_key US-4402 KFF-4402  # Gunnison National Forest
    set_key US-4403 KFF-4647  # Medicine Bow - Routt National Forest; WWFF candidates: KFF-4403, KFF-4647
    set_key US-4404 KFF-4404  # Pike National Forest
    set_key US-4405 KFF-4405  # Rio Grande National Forest
    set_key US-4406 KFF-4406  # Roosevelt National Forest
    set_key US-4407 KFF-4407  # San Isabel National Forest
    set_key US-4408 KFF-4408  # San Juan National Forest
    set_key US-4409 KFF-4409  # Uncompahgre National Forest
    set_key US-4410 KFF-4410  # White River National Forest
    set_key US-4411 KFF-4411  # Browns Canyon National Monument
    set_key US-4412 KFF-4412  # Canyons of the Ancients National Monument
    set_key US-4413 KFF-4413  # Chimney Rock National Monument
    set_key US-4414 KFF-4414  # Angelina National Forest
    set_key US-4415 KFF-4415  # Davy Crockett National Forest
    set_key US-4416 KFF-4416  # Sabine National Forest
    set_key US-4417 KFF-4417  # Sam Houston National Forest
    set_key US-4418 KFF-4418  # E.O. Siecke State Forest
    set_key US-4419 KFF-4419  # I.D. Farichild State Forest
    set_key US-4420 KFF-4420  # John Henry Kirby Memorial State Forest
    set_key US-4421 KFF-4421  # Masterson State Forest
    set_key US-4422 KFF-4422  # W. Goodrich Jones State Forest
    set_key US-4423 KFF-4423  # Spring Creek Forest State Preserve
    set_key US-4424 NIL-0000  # Ouachita National Forest (OK); WWFF candidates: KFF-4424, KFF-4601
    set_key US-4425 KFF-4425  # Ozark-St. Francis National Forest
    set_key US-4426 KFF-4426  # Poison Springs State Forest
    set_key US-4427 NIL-0000  # Apache National Forest (NM); WWFF candidates: KFF-4427, KFF-4654, KFF-4656
    set_key US-4428 KFF-4428  # Coconino National Forest
    set_key US-4429 NIL-0000  # Coronado National Forest (NM); WWFF candidates: KFF-4429, KFF-4603
    set_key US-4430 KFF-4430  # Kaibab National Forest
    set_key US-4431 KFF-4431  # Prescott National Forest
    set_key US-4432 KFF-4432  # Tonto National Forest
    set_key US-4433 KFF-4433  # Agua Fria National Monument
    set_key US-4434 KFF-4434  # Ironwood Forest National Monument
    set_key US-4435 KFF-4435  # Sonoran Desert National Monument
    set_key US-4436 KFF-4436  # Vermilion Cliffs National Monument
    set_key US-4437 KFF-4437  # Big Bend of the Colorado State Recreation Area
    set_key US-4438 KFF-4438  # Buckland Station State Park
    set_key US-4440 KFF-4440  # Elgin School House State Park
    set_key US-4441 KFF-4441  # Lahontan State Recreation Area
    set_key US-4442 KFF-4442  # Walker Lake State Recreation Area
    set_key US-4443 KFF-4443  # Old Las Vegas Mormon Fort State Park
    set_key US-4444 KFF-4444  # Rye Patch State Recreation Area
    set_key US-4445 KFF-4445  # South Fork State Recreation Area
    set_key US-4446 KFF-4446  # Wild Horse State Recreation Area
    set_key US-4447 KFF-4457  # Chugach National Forest
    set_key US-4448 KFF-4458  # Tongass National Forest
    set_key US-4449 KFF-4502  # Conecuh National Forest
    set_key US-4450 KFF-4503  # Talladega National Forest
    set_key US-4451 KFF-4504  # Tuskegee National Forest
    set_key US-4452 KFF-4501  # William B. Bankhead National Forest
    set_key US-4453 KFF-4480  # Angeles National Forest
    set_key US-4454 KFF-4481  # Cleveland National Forest
    set_key US-4455 KFF-4482  # Eldorado National Forest
    set_key US-4456 NIL-0000  # Inyo National Forest (NV); WWFF candidates: KFF-4483, KFF-4609
    set_key US-4457 NIL-0000  # Klamath National Forest (OR); WWFF candidates: KFF-4484, KFF-4610
    set_key US-4458 NIL-0000  # Lake Tahoe Basin Management Unit National Forest (NV); WWFF candidates: KFF-4485, KFF-4611
    set_key US-4459 KFF-4486  # Lassen National Forest
    set_key US-4460 KFF-4487  # Mendocino National Forest
    set_key US-4461 KFF-4488  # Modoc National Forest
    set_key US-4462 KFF-4489  # Plumas National Forest
    set_key US-4463 KFF-4490  # San Bernardino National Forest
    set_key US-4464 KFF-4491  # Sequoia National Forest
    set_key US-4465 KFF-4492  # Shasta-Trinity National Forest
    set_key US-4466 KFF-4493  # Sierra National Forest
    set_key US-4467 KFF-4494  # Six Rivers National Forest
    set_key US-4468 KFF-4495  # Stanislaus National Forest
    set_key US-4469 KFF-4496  # Tahoe National Forest
    set_key US-4470 KFF-4498  # Apalachicola National Forest
    set_key US-4471 KFF-4500  # Ocala National Forest
    set_key US-4472 KFF-4499  # Osceola National Forest
    set_key US-4473 NIL-0000  # Oconee National Forest; WWFF candidates: KFF-4505, KFF-4506
    set_key US-4474 KFF-4465  # Boise National Forest
    set_key US-4475 NIL-0000  # Targhee National Forest (WY); WWFF candidates: KFF-4466, KFF-4642, KFF-4643, KFF-4644, KFF-4645
    set_key US-4476 KFF-4467  # Clearwater National Forest
    set_key US-4477 NIL-0000  # Kaniksu National Forest (WA); WWFF candidates: KFF-4468, KFF-4469, KFF-4470, KFF-4607, KFF-4608
    set_key US-4478 KFF-4471  # Nez Perce National Forest
    set_key US-4479 KFF-4472  # Payette National Forest
    set_key US-4480 NIL-0000  # Challis National Forest; WWFF candidates: KFF-4473, KFF-4653
    set_key US-4481 NIL-0000  # Sawtooth National Forest (UT); WWFF candidates: KFF-4474, KFF-4619
    set_key US-4482 KFF-4517  # Shawnee National Forest
    set_key US-4483 KFF-4518  # Hoosier National Forest
    set_key US-4484 KFF-4511  # Daniel Boone National Forest
    set_key US-4486 KFF-4577  # Kisatchie National Forest
    set_key US-4487 KFF-4523  # Hiawatha National Forest
    set_key US-4488 KFF-4524  # Huron National Forest
    set_key US-4489 KFF-4526  # Ottawa National Forest
    set_key US-4490 KFF-4529  # Chippewa National Forest
    set_key US-4491 KFF-4530  # Superior National Forest
    set_key US-4492 KFF-4532  # Mark Twain National Forest
    set_key US-4493 KFF-4533  # Bienville National Forest
    set_key US-4494 KFF-4535  # De Soto National Forest
    set_key US-4495 KFF-4534  # Delta National Forest
    set_key US-4496 KFF-4536  # Holly Springs National Forest
    set_key US-4497 KFF-4537  # Homochitto National Forest
    set_key US-4498 KFF-4538  # Tombigbee National Forest
    set_key US-4499 NIL-0000  # Deerlodge National Forest (MT); WWFF candidates: KFF-4454, KFF-4651
    set_key US-4500 NIL-0000  # Bitterroot National Forest (ID); WWFF candidates: KFF-4455, KFF-4605
    set_key US-4501 NIL-0000  # Custer National Forest (SD); WWFF candidates: KFF-4456, KFF-4640
    set_key US-4502 KFF-4459  # Flathead National Forest
    set_key US-4503 KFF-4641  # Gallatin National Forest (MT)
    set_key US-4504 NIL-0000  # Lewis and Clark National Forest (MT); WWFF candidates: KFF-4460, KFF-4462
    set_key US-4505 NIL-0000  # Kootenai National Forest (ID); WWFF candidates: KFF-4461, KFF-4606
    set_key US-4507 KFF-4463  # Lolo National Forest
    set_key US-4508 KFF-4515  # Croatan National Forest
    set_key US-4509 KFF-4512  # Nantahala National Forest
    set_key US-4510 KFF-4513  # Pisgah National Forest
    set_key US-4511 KFF-4514  # Uwharrie National Forest
    set_key US-4512 NIL-0000  # White Mountain National Forest (ME); WWFF candidates: KFF-4522, KFF-4614
    set_key US-4513 KFF-4475  # Carson National Forest
    set_key US-4514 KFF-4476  # Cibola National Forest
    set_key US-4515 KFF-4477  # Gila National Forest
    set_key US-4516 KFF-4478  # Lincoln National Forest
    set_key US-4517 KFF-4479  # Santa Fe National Forest
    set_key US-4518 KFF-4497  # Finger Lakes National Forest
    set_key US-4519 KFF-4541  # Connetquot River State Park Preserve
    set_key US-4521 KFF-4527  # Wayne National Forest
    set_key US-4522 KFF-4507  # Francis Marion National Forest
    set_key US-4523 KFF-4508  # Sumter National Forest
    set_key US-4524 KFF-4531  # Black Hills National Forest; WWFF candidates: KFF-4531, KFF-4604
    set_key US-4525 NIL-0000  # Cherokee National Forest (VA); WWFF candidates: KFF-4516, KFF-4612, KFF-4613
    set_key US-4526 NIL-0000  # George Washington National Forest (WV); WWFF candidates: KFF-4509, KFF-4510, KFF-6295, KFF-6296, KFF-6297
    set_key US-4527 KFF-4521  # Green Mountain National Forest
    set_key US-4528 KFF-4450  # Colville National Forest
    set_key US-4529 KFF-4451  # Gifford Pinchot National Forest
    set_key US-4530 NIL-0000  # Snoqualmie National Forest; WWFF candidates: KFF-4452, KFF-4650
    set_key US-4531 NIL-0000  # Wenatchee National Forest; WWFF candidates: KFF-4464, KFF-4652
    set_key US-4532 KFF-4453  # Olympic National Forest
    set_key US-4533 NIL-0000  # Nicolet National Forest; WWFF candidates: KFF-4519, KFF-4520
    set_key US-4534 KFF-4447  # Bighorn National Forest
    set_key US-4535 NIL-0000  # Teton National Forest; WWFF candidates: KFF-4448, KFF-4649
    set_key US-4536 KFF-4449  # Shoshone National Forest
    set_key US-4537 KFF-5145  # Admiralty Island National Monument
    set_key US-4538 KFF-5146  # Misty Fjords National Monument
    set_key US-4539 KFF-5131  # Berryessa Snow Mountain National Monument
    set_key US-4540 KFF-5132  # California Coastal National Monument
    set_key US-4541 KFF-5133  # Carrizo Plain National Monument
    set_key US-4542 KFF-5134  # Fort Ord National Monument
    set_key US-4543 KFF-5135  # Mojave Trails National Monument
    set_key US-4544 KFF-5149  # San Gabriel Mountains National Monument
    set_key US-4545 KFF-5136  # Sand to Snow National Monument
    set_key US-4546 KFF-5137  # Santa Rosa and San Jacinto Mountains National Monument
    set_key US-4548 KFF-5138  # Pompeys Pillar National Monument
    set_key US-4549 KFF-5139  # Upper Missouri River Breaks National Monument
    set_key US-4551 KFF-5141  # Organ Mountains-Desert Peaks National Monument
    set_key US-4552 KFF-5142  # Prehistoric Trackways National Monument
    set_key US-4553 KFF-5143  # Rio Grande del Norte National Monument
    set_key US-4555 KFF-5150  # Hanford Reach National Monument
    set_key US-4556 NIL-0000  # Appalachian Trail National Scenic Trail (ME); WWFF candidates: KFF-5014, KFF-5015, KFF-5016, KFF-5017, KFF-5018, KFF-5019, KFF-5020, KFF-5021, KFF-5022, KFF-5023, KFF-5024, KFF-5025, KFF-5026, KFF-5027
    set_key US-4557 KFF-5041  # Arizona Trail National Scenic Trail
    set_key US-4558 NIL-0000  # Continental Divide Trail National Scenic Trail (NM); WWFF candidates: KFF-5047, KFF-5048, KFF-5049, KFF-5050, KFF-5051
    set_key US-4559 KFF-5052  # Florida Trail National Scenic Trail
    set_key US-4560 NIL-0000  # Natchez Trace Trail (MS); WWFF candidates: KFF-6602, KFF-6603, KFF-6604
    set_key US-4561 NIL-0000  # New England Trail National Scenic Trail (MA); WWFF candidates: KFF-5039, KFF-5040
    set_key US-4562 NIL-0000  # Pacific Crest Trail National Scenic Trail (CA); WWFF candidates: KFF-5036, KFF-5042, KFF-5043
    set_key US-4563 NIL-0000  # Pacific Northwest National Scenic Trail (WA); WWFF candidates: KFF-5044, KFF-5045, KFF-5046
    set_key US-4564 NIL-0000  # Potomac Heritage National Scenic Trail (VA); WWFF candidates: KFF-5034, KFF-5035, KFF-5037, KFF-5038
    set_key US-4583 KFF-4525  # Manistee National Forest
    set_key US-4586 KFF-6049  # Big Lazer Creek Wildlife Management Area
    set_key US-4588 KFF-4544  # Taconic Mountains Ramble State Park
    set_key US-4589 KFF-4542  # Molly's Falls Pond State Park
    set_key US-4590 KFF-4543  # Muckross State Park
    set_key US-4601 KFF-4731  # Boggs Mountain Demonstration State Forest
    set_key US-4603 KFF-4733  # Jackson Demonstration State Forest
    set_key US-4605 KFF-4735  # LaTour Demonstration State Forest
    set_key US-4606 KFF-4736  # Mount Zion Demonstration State Forest
    set_key US-4607 KFF-4737  # Mountain Home Demonstration State Forest
    set_key US-4608 KFF-4738  # Soquel Demonstration State Forest
    set_key US-4609 KFF-4866  # Blackbird State Forest
    set_key US-4610 KFF-4867  # Redden State Forest
    set_key US-4611 KFF-4868  # Taber State Forest
    set_key US-4612 KFF-5156  # Belmore State Forest
    set_key US-4613 KFF-5157  # Big Shoals State Forest
    set_key US-4614 KFF-5158  # Blackwater River State Forest
    set_key US-4615 KFF-5159  # Carl Duval Moore State Forest
    set_key US-4616 KFF-5160  # Cary State Forest
    set_key US-4617 KFF-5161  # Charles H. Bronson State Forest
    set_key US-4619 KFF-5162  # Deep Creek State Forest
    set_key US-4620 KFF-5163  # Etoniah Creek State Forest
    set_key US-4621 KFF-5164  # Four Creeks State Forest
    set_key US-4622 KFF-5165  # Goethe State Forest
    set_key US-4623 KFF-5166  # Holopaw State Forest
    set_key US-4624 KFF-5167  # Indian Lake State Forest
    set_key US-4625 KFF-5168  # Jennings State Forest
    set_key US-4626 KFF-5169  # John M. Bethea State Forest
    set_key US-4627 KFF-5170  # Lake George State Forest
    set_key US-4628 KFF-5171  # Lake Talquin State Forest
    set_key US-4629 KFF-5172  # Lake Wales Ridge State Forest
    set_key US-4630 KFF-5173  # Little Big Econ State Forest
    set_key US-4631 KFF-5174  # Matanzas State Forest
    set_key US-4632 KFF-5175  # Myakka State Forest
    set_key US-4633 KFF-5177  # Okaloacoochee Slough State Forest
    set_key US-4634 KFF-5179  # Picayune Strand State Forest
    set_key US-4635 KFF-5180  # Pine Log State Forest
    set_key US-4636 KFF-5182  # Point Washington State Forest
    set_key US-4637 KFF-5183  # Ralph E. Simmons Memorial State Forest
    set_key US-4638 KFF-5184  # Ross Prairie State Forest
    set_key US-4639 KFF-5185  # Seminole State Forest
    set_key US-4640 KFF-5186  # Tate's Hell State Forest
    set_key US-4641 KFF-5187  # Tiger Bay State Forest
    set_key US-4642 KFF-5188  # Twin Rivers State Forest
    set_key US-4643 KFF-5189  # Wakulla State Forest
    set_key US-4644 KFF-5190  # Watson Island State Forest
    set_key US-4645 KFF-5191  # Welaka State Forest
    set_key US-4646 KFF-5192  # Withlacoochee State Forest
    set_key US-4647 KFF-6048  # Bartram Forest Wildlife Management Area
    set_key US-4648 KFF-6040  # Bartram Educational State Forest
    set_key US-4650 KFF-6041  # Dawson State Forest
    set_key US-4651 KFF-6042  # Dixon Memorial State Forest
    set_key US-4653 KFF-6043  # Paulding Forest Wildlife Management Area
    set_key US-4654 KFF-6044  # Spirit Creek Educational State Forest
    set_key US-4659 KFF-6550  # Loess Hills State Forest
    set_key US-4661 KFF-6551  # Shimek State Forest
    set_key US-4662 KFF-6552  # Stephens State Forest
    set_key US-4664 KFF-6553  # Yellow River State Forest
    set_key US-4687 KFF-7272  # Dewey Lake State Forest
    set_key US-4688 KFF-6865  # Kentenia State Forest
    set_key US-4689 KFF-6866  # Kentucky Ridge State Forest
    set_key US-4690 KFF-6889  # Knobs State Forest
    set_key US-4692 KFF-6867  # Pennyrile State Forest
    set_key US-4693 KFF-6869  # Tygarts State Forest
    set_key US-4695 KFF-5737  # Nantucket State Forest
    set_key US-4696 KFF-5730  # Manuel F. Correllus State Forest
    set_key US-4697 KFF-5745  # Shawme-Crowell State Forest
    set_key US-4698 KFF-5722  # Freetown-Fall River State Forest
    set_key US-4700 KFF-5736  # Myles Standish State Forest
    set_key US-4701 KFF-5717  # Douglas State Forest
    set_key US-4702 KFF-5719  # F. Gilbert Hills State Forest
    set_key US-4703 KFF-5725  # Granville State Forest
    set_key US-4704 KFF-5721  # Franklin State Forest
    set_key US-4705 KFF-5713  # Brimfield State Forest
    set_key US-4706 KFF-5743  # Sandisfield State Forest
    set_key US-4707 KFF-5747  # Tolland State Forest
    set_key US-4709 KFF-5735  # Mount Washington State Forest
    set_key US-4711 KFF-5712  # Beartown State Forest
    set_key US-4712 KFF-5748  # Upton State Forest
    set_key US-4713 KFF-5746  # Spencer State Forest
    set_key US-4714 KFF-5715  # Chester-Blandford State Forest
    set_key US-4717 KFF-5738  # October Mountain State Forest
    set_key US-4718 KFF-5731  # Middlefield State Forest
    set_key US-4719 KFF-5740  # Peru State Forest
    set_key US-4721 KFF-5754  # Worthington State Forest
    set_key US-4722 KFF-5724  # Gilbert A. Bliss State Forest
    set_key US-4724 KFF-5716  # D.A.R. State Forest
    set_key US-4726 KFF-5714  # Bryant Mountain State Forest
    set_key US-4727 KFF-5741  # Pittsfield State Forest
    set_key US-4729 KFF-5720  # Federated Women's Club State Forest
    set_key US-4732 KFF-5728  # Leominster State Forest
    set_key US-4733 KFF-5753  # Windsor State Forest
    set_key US-4734 KFF-5749  # Wendell State Forest
    set_key US-4736 KFF-5750  # West Bridgewater State Forest
    set_key US-4738 KFF-5727  # Kenneth Dubuque Memorial State Forest
    set_key US-4743 KFF-5744  # Savoy Mountain State Forest
    set_key US-4744 KFF-5718  # Erving State Forest
    set_key US-4745 KFF-5739  # Otter River State Forest
    set_key US-4746 KFF-5726  # Harold Parker State Forest
    set_key US-4747 KFF-5732  # Mohawk Trail State Forest
    set_key US-4749 KFF-5729  # Lowell-Dracut-Tyngsboro State Forest
    set_key US-4752 KFF-5751  # Willard Brook State Forest
    set_key US-4755 KFF-5752  # Willowdale State Forest
    set_key US-4756 KFF-5734  # Mount Grace State Forest
    set_key US-4757 KFF-5723  # Georgetown Rowley State Forest
    set_key US-4758 KFF-5733  # Monroe State Forest
    set_key US-4763 KFF-4773  # Cedarville State Forest
    set_key US-4764 KFF-4771  # Elk Neck State Forest
    set_key US-4765 KFF-4768  # Garrett State Forest
    set_key US-4766 KFF-4769  # Green Ridge State Forest
    set_key US-4767 KFF-4778  # Pocomoke State Forest
    set_key US-4768 KFF-4767  # Potomac State Forest
    set_key US-4769 KFF-4776  # Salem State Forest
    set_key US-4770 KFF-4770  # Savage River State Forest
    set_key US-4771 KFF-4775  # St. Inigoes State Forest
    set_key US-4780 KFF-5465  # Badoura State Forest
    set_key US-4781 KFF-5466  # Battleground State Forest
    set_key US-4782 KFF-5467  # Bear Island State Forest
    set_key US-4783 KFF-5468  # Beltrami Island State Forest
    set_key US-4784 KFF-5469  # Big Fork State Forest
    set_key US-4785 KFF-5470  # Birch Lakes State Forest
    set_key US-4786 KFF-5471  # Blackduck State Forest
    set_key US-4787 KFF-5472  # Bowstring State Forest
    set_key US-4788 KFF-5473  # Buena Vista State Forest
    set_key US-4789 KFF-5474  # Burntside State Forest
    set_key US-4790 KFF-5476  # Chengwatana State Forest
    set_key US-4791 KFF-5477  # Cloquet Valley State Forest
    set_key US-4792 KFF-5478  # Crow Wing State Forest
    set_key US-4793 KFF-5479  # D.A.R. State Forest
    set_key US-4794 KFF-5480  # Emily State Forest
    set_key US-4795 KFF-5481  # Finland State Forest
    set_key US-4796 KFF-5482  # Fond du Lac State Forest
    set_key US-4797 KFF-5483  # Foot Hills State Forest
    set_key US-4798 KFF-5484  # General C. C. Andrews State Forest
    set_key US-4799 KFF-5485  # George Washington State Forest
    set_key US-4800 KFF-5486  # Golden Anniversary State Forest
    set_key US-4801 KFF-5487  # Grand Portage State Forest
    set_key US-4802 KFF-5488  # Hill River State Forest
    set_key US-4803 KFF-5489  # Huntersville State Forest
    set_key US-4804 KFF-5490  # Insula Lake State Forest
    set_key US-4805 KFF-5491  # Lake Jeanette State Forest
    set_key US-4806 KFF-5492  # Kabetogama State Forest
    set_key US-4807 KFF-5493  # Koochiching State Forest
    set_key US-4808 KFF-5494  # Lake Isabella State Forest
    set_key US-4809 KFF-5495  # Lake of the Woods State Forest
    set_key US-4810 KFF-5496  # Land O'Lakes State Forest
    set_key US-4811 KFF-5497  # Lost River State Forest
    set_key US-4812 KFF-5498  # Lyons State Forest
    set_key US-4813 KFF-5499  # Mississippi Headwaters State Forest
    set_key US-4814 KFF-5500  # Nemadji State Forest
    set_key US-4815 KFF-5501  # Northwest Angle State Forest
    set_key US-4816 KFF-5502  # Pat Bayle State Forest
    set_key US-4817 KFF-5503  # Paul Bunyan State Forest
    set_key US-4818 KFF-5504  # Pillsbury State Forest
    set_key US-4819 KFF-5505  # Pine Island State Forest
    set_key US-4820 KFF-5506  # Red Lake State Forest
    set_key US-4821 KFF-5507  # Remer State Forest
    set_key US-4822 KFF-5508  # Richard J. Dorer Memorial Hardwood State Forest
    set_key US-4823 KFF-5509  # Rum River State Forest
    set_key US-4824 KFF-5510  # St. Croix State Forest
    set_key US-4825 KFF-5511  # Sand Dunes State Forest
    set_key US-4826 KFF-5512  # Savanna State Forest
    set_key US-4827 KFF-5513  # Smokey Bear State Forest
    set_key US-4828 KFF-5514  # Smoky Hills State Forest
    set_key US-4829 KFF-5515  # Snake River State Forest
    set_key US-4830 KFF-5516  # Solana State Forest
    set_key US-4831 KFF-5517  # Sturgeon River State Forest
    set_key US-4832 KFF-5518  # Two Inlets State Forest
    set_key US-4833 KFF-5519  # Waukenabo State Forest
    set_key US-4834 KFF-5520  # Wealthwood State Forest
    set_key US-4835 KFF-5521  # Welsh Lake State Forest
    set_key US-4836 KFF-5522  # White Earth State Forest
    set_key US-4837 KFF-5523  # Whiteface River State Forest
    set_key US-4838 KFF-6300  # Busiek State Forest
    set_key US-4839 KFF-6421  # Lester R. Davis Memorial State Forest
    set_key US-4840 KFF-6301  # Reifsnider State Forest
    set_key US-4842 KFF-6417  # Vanderhoef Memorial State Forest
    set_key US-4843 KFF-6420  # Murphy Memorial State Forest
    set_key US-4852 KFF-4791  # Bladen Lakes State Forest
    set_key US-4853 KFF-4784  # Clemmons Educational State Forest
    set_key US-4854 KFF-6270  # DuPont State Recreational Forest State Forest
    set_key US-4855 KFF-4793  # Headwaters State Forest
    set_key US-4856 KFF-4785  # Holmes Educational State Forest
    set_key US-4857 KFF-4786  # Jordan Lake Educational State Forest
    set_key US-4858 KFF-4787  # Mountain Island Educational State Forest
    set_key US-4859 KFF-4788  # Rendezvous Mountain Educational State Forest
    set_key US-4860 KFF-4789  # Turnbull Creek Educational State Forest
    set_key US-4861 KFF-4790  # Tuttle Educational State Forest
    set_key US-4866 KFF-7304  # Ames State Forest
    set_key US-4868 KFF-5199  # Annett State Forest
    set_key US-4874 KFF-5200  # Belknap Mountain State Forest
    set_key US-4877 KFF-5201  # Black Mountain State Forest
    set_key US-4880 KFF-7305  # Bowditch-Runnells State Forest
    set_key US-4881 KFF-5202  # Cape Horn State Forest
    set_key US-4882 KFF-7306  # Carroll State Forest
    set_key US-4886 KFF-5203  # Connecticut Lakes State Forest
    set_key US-4889 KFF-5204  # Conway Common Lands State Forest
    set_key US-4897 KFF-7307  # Dodge Brook State Forest
    set_key US-4899 KFF-5205  # Fall Mountain State Forest
    set_key US-4903 KFF-5206  # Fox State Forest
    set_key US-4905 KFF-5207  # Gile State Forest
    set_key US-4912 KFF-5208  # Hemenway State Forest
    set_key US-4914 KFF-5209  # Honey Brook State Forest
    set_key US-4915 KFF-5210  # Hubbard Hill State Forest
    set_key US-4918 KFF-5211  # Kearsarge Mountain State Forest
    set_key US-4927 KFF-5212  # Low State Forest
    set_key US-4930 KFF-5213  # Mast Yard State Forest
    set_key US-4931 KFF-5214  # Max Israel State Forest
    set_key US-4933 KFF-5215  # Merrimack River State Forest
    set_key US-4934 KFF-5216  # Merriman State Forest
    set_key US-4936 KFF-5217  # Nash Stream Forest State Forest
    set_key US-4937 KFF-7383  # Nottingham State Forest
    set_key US-4938 KFF-5218  # Nursery State Forest
    set_key US-4944 KFF-5219  # Pine River State Forest
    set_key US-4948 KFF-5220  # Province Road State Forest
    set_key US-4949 KFF-7384  # Ragged Mountain State Forest
    set_key US-4953 KFF-5221  # Russell-Abbott State Forest
    set_key US-4958 KFF-5222  # Second Presidential State Forest
    set_key US-4964 KFF-7385  # Soucook River State Forest
    set_key US-4970 KFF-7386  # Taylor State Forest
    set_key US-4975 KFF-5223  # Vincent State Forest
    set_key US-4981 KFF-5224  # William Thomas State Forest
    set_key US-4991 KFF-4755  # Abram S. Hewitt State Forest
    set_key US-4992 KFF-4756  # Bass River State Forest
    set_key US-4993 KFF-4757  # Belleplain State Forest
    set_key US-4994 KFF-4758  # Brendan T. Byrne State Forest
    set_key US-4995 KFF-4759  # Jenny Jump State Forest
    set_key US-4996 KFF-4760  # Norvin Green State Forest
    set_key US-4997 KFF-4761  # Penn State Forest
    set_key US-4998 KFF-4762  # Ramapo Mountain State Forest
    set_key US-4999 KFF-4763  # Stokes State Forest
    set_key US-5000 KFF-4764  # Wharton State Forest
    set_key US-5001 KFF-4765  # Worthington State Forest
    set_key US-5004 KFF-7092  # East Osceola State Forest
    set_key US-5005 KFF-7111  # East Otto State Forest
    set_key US-5013 KFF-7398  # Fall Brook State Forest
    set_key US-5018 KFF-7394  # Five Streams State Forest
    set_key US-5022 KFF-6986  # Frank E. Jadwin Memorial State Forest
    set_key US-5025 KFF-7083  # Gas Springs State Forest
    set_key US-5028 KFF-7404  # Genegantslet State Forest
    set_key US-5030 KFF-7494  # Gillies Hill State Forest
    set_key US-5033 KFF-7081  # Golden Hill State Forest
    set_key US-5036 KFF-7089  # Gould Corners State Forest
    set_key US-5038 KFF-7015  # Grant Powell State Forest
    set_key US-5042 KFF-7080  # Grigg’s Gulf State Forest
    set_key US-5043 KFF-7500  # Goundry Hill State Forest
    set_key US-5044 KFF-7502  # Hall Island State Forest
    set_key US-5045 KFF-7051  # Hammond Hill State Forest
    set_key US-5046 KFF-7082  # Harris Hill State Forest
    set_key US-5049 KFF-7118  # Hatch Creek State Forest
    set_key US-5051 KFF-7018  # Hemlock-Canadice State Forest
    set_key US-5054 KFF-7503  # High Flats State Forest
    set_key US-5059 KFF-7100  # Hinckley State Forest
    set_key US-5063 KFF-7085  # Hoxie Gorge State Forest
    set_key US-5064 KFF-5372  # Huckleberry Ridge State Forest
    set_key US-5066 KFF-7110  # Hunts Pond State Forest
    set_key US-5071 KFF-7038  # James Kennedy State Forest
    set_key US-5072 KFF-7112  # Jenksville State Forest
    set_key US-5074 KFF-7094  # Karr Valley Creek State Forest
    set_key US-5075 KFF-7133  # Kasoag State Forest
    set_key US-5076 KFF-7491  # Keeney Swamp State Forest
    set_key US-5081 KFF-7070  # Klipnocky State Forest
    set_key US-5084 KFF-7484  # Albert J. Woodford Memorial State Forest
    set_key US-5085 KFF-7490  # Allen Lake State Forest
    set_key US-5093 KFF-7120  # Baker School House State Forest
    set_key US-5096 KFF-7072  # Balsam Swamp State Forest
    set_key US-5103 KFF-7097  # Battle Hill State Forest
    set_key US-5109 KFF-7439  # Beartown State Forest
    set_key US-5110 KFF-7052  # Beaver Creek (St Lawrence) State Forest
    set_key US-5111 KFF-7056  # Beaver Creek (Madison) State Forest
    set_key US-5112 KFF-7129  # Beaver Dam State Forest
    set_key US-5115 KFF-7024  # Beaver Meadow State Forest
    set_key US-5120 KFF-7046  # Big Brook State Forest
    set_key US-5122 KFF-7057  # Birdseye Hollow State Forest
    set_key US-5126 KFF-7499  # Bobell State Forest
    set_key US-5131 KFF-7406  # Boutwell Hill State Forest
    set_key US-5138 KFF-7099  # Buck Hill State Forest
    set_key US-5139 KFF-7497  # Buck's Brook State Forest
    set_key US-5141 KFF-7495  # Bucktooth State Forest
    set_key US-5142 KFF-7402  # Bully Hill State Forest
    set_key US-5145 KFF-7007  # Burnt-Rossman Hills State Forest
    set_key US-5147 KFF-7059  # Bush Hill State Forest
    set_key US-5158 KFF-7117  # Canaseraga State Forest
    set_key US-5166 KFF-7011  # Charles E. Baker State Forest
    set_key US-5167 KFF-7401  # Charleston State Forest
    set_key US-5168 KFF-7043  # Chateaugay State Forest
    set_key US-5175 KFF-7068  # Clark Hill State Forest
    set_key US-5179 KFF-7496  # Cobb Creek State Forest
    set_key US-5184 KFF-7488  # Coon Hollow State Forest
    set_key US-5188 KFF-7493  # Coyle Hill State Forest
    set_key US-5190 KFF-7128  # Crab Hollow State Forest
    set_key US-5193 KFF-7026  # Cuyler Hill State Forest
    set_key US-5195 KFF-7017  # Danby State Forest
    set_key US-5199 KFF-7000  # Deer River State Forest
    set_key US-5208 KFF-7489  # Dunkin's Reserve State Forest
    set_key US-5213 KFF-5373  # Neversink River State Conservation Area
    set_key US-5214 KFF-7102  # Newfield State Forest
    set_key US-5216 KFF-7062  # Nine Mile Creek State Forest
    set_key US-5217 KFF-7074  # North Harmony State Forest
    set_key US-5220 KFF-6709  # Flying Eagle Preserve State Conservation Area
    set_key US-5234 KFF-7053  # Palmer’s Pond State Forest
    set_key US-5235 KFF-7123  # Panama State Forest
    set_key US-5238 KFF-7498  # Patria State Forest
    set_key US-5240 KFF-7067  # Peck Hill State Forest
    set_key US-5241 KFF-7050  # Penn Mountain State Forest
    set_key US-5243 KFF-7029  # Morgan Hill State Forest
    set_key US-5245 KFF-7071  # Phillips Creek State Forest
    set_key US-5248 KFF-7087  # Pinckney State Forest
    set_key US-5253 KFF-7127  # Pittstown State Forest
    set_key US-5259 KFF-7125  # Point Rock State Forest
    set_key US-5260 KFF-7077  # Popple Pond State Forest
    set_key US-5272 KFF-7073  # Rensselaerville State Forest
    set_key US-5273 KFF-7093  # Robinson Hollow State Forest
    set_key US-5285 KFF-7069  # Salmon River State Forest
    set_key US-5288 KFF-7075  # Sand Flats State Forest
    set_key US-5291 KFF-7025  # Sears Pond State Forest
    set_key US-5293 KFF-5374  # Shawangunk Ridge State Forest
    set_key US-5294 KFF-7028  # Shindagin Hollow State Forest
    set_key US-5298 KFF-7122  # Slader Creek State Forest
    set_key US-5303 KFF-7501  # South Hammond State Forest
    set_key US-5304 KFF-7114  # South Hill (Chenango) State Forest
    set_key US-5306 KFF-7400  # South Valley State Forest
    set_key US-5312 KFF-7397  # Steam Mill State Forest
    set_key US-5314 KFF-7393  # Stewart State Forest
    set_key US-5315 KFF-5993  # Stid Hill Wildlife Management Area
    set_key US-5322 KFF-7013  # Sugar Hill State Forest
    set_key US-5323 KFF-7039  # Summer Hill State Forest
    set_key US-5325 KFF-7090  # Swancott Hill State Forest
    set_key US-5329 KFF-7047  # Taconic Ridge State Forest
    set_key US-5330 KFF-6714  # Green Swamp Wilderness Park Reserve
    set_key US-5332 KFF-7035  # Taylor Valley State Forest
    set_key US-5333 KFF-7033  # Terry Mountain State Forest
    set_key US-5339 KFF-7396  # Titusville Mountain State Forest
    set_key US-5344 KFF-7115  # Tri-County State Forest
    set_key US-5348 KFF-7002  # Tug Hill State Forest
    set_key US-5349 KFF-7076  # Tuller Hill State Forest
    set_key US-5353 KFF-7032  # Turnpike State Forest
    set_key US-5354 KFF-7483  # Urbana State Forest
    set_key US-5356 KFF-7492  # Vandermark State Forest
    set_key US-5357 KFF-5375  # Vernooy Kill State Forest
    set_key US-5367 KFF-7113  # Whalen Memorial State Forest
    set_key US-5370 KFF-7486  # Whiskey Flats State Forest
    set_key US-5375 KFF-7012  # Winona State Forest
    set_key US-5378 KFF-7399  # Wolf Lake State Forest
    set_key US-5382 KFF-7116  # Yellow Barn State Forest
    set_key US-5388 KFF-7487  # Lassellsville State Forest
    set_key US-5391 KFF-6996  # Lesser Wilderness State Forest
    set_key US-5392 KFF-7036  # Lincklaen State Forest
    set_key US-5394 KFF-7130  # Line Brook State Forest
    set_key US-5396 KFF-7060  # Long Pond State Forest
    set_key US-5397 KFF-7045  # Lookout State Forest
    set_key US-5400 KFF-7403  # Ludlow Creek State Forest
    set_key US-5401 KFF-7096  # Lutheranville State Forest
    set_key US-5404 KFF-7407  # Mad River State Forest
    set_key US-5405 KFF-7485  # Mallet Pond State Forest
    set_key US-5408 KFF-7065  # Mariposa State Forest
    set_key US-5412 KFF-7021  # McCarty Hill State Forest
    set_key US-5415 KFF-7027  # Melondy Hill State Forest
    set_key US-5416 KFF-7126  # Michigan Hill State Forest
    set_key US-5420 KFF-7124  # Mohawk Springs State Forest
    set_key US-5430 KFF-7104  # Mount Pleasant State Forest
    set_key US-5433 KFF-7063  # Muller Hill State Forest
    set_key US-5435 KFF-4987  # Beaver Creek State Forest
    set_key US-5436 KFF-4988  # Blue Rock State Forest
    set_key US-5437 KFF-4989  # Brush Creek State Forest
    set_key US-5438 KFF-4990  # Dean State Forest
    set_key US-5439 KFF-4991  # Fernwood State Forest
    set_key US-5440 KFF-4992  # Gifford State Forest
    set_key US-5441 KFF-4993  # Harrison State Forest
    set_key US-5442 KFF-4994  # Hocking State Forest
    set_key US-5443 KFF-4995  # Maumee State Forest
    set_key US-5444 KFF-4996  # Mohican-Memorial State Forest
    set_key US-5445 KFF-4997  # Perry State Forest
    set_key US-5446 KFF-4998  # Pike State Forest
    set_key US-5447 KFF-4999  # Richland Furnace State Forest
    set_key US-5448 KFF-5000  # Scioto Trail State Forest
    set_key US-5449 KFF-5001  # Shade River State Forest
    set_key US-5450 KFF-5002  # Shawnee State Forest
    set_key US-5451 KFF-5003  # Sunfish Creek State Forest
    set_key US-5452 KFF-5004  # Tar Hollow State Forest
    set_key US-5453 KFF-5005  # Vinton Furnace Experimental State Forest
    set_key US-5454 KFF-5006  # Yellow Creek State Forest
    set_key US-5455 KFF-5007  # Zaleski State Forest
    set_key US-5462 KFF-4895  # Bald Eagle State Forest
    set_key US-5463 KFF-4896  # Buchanan State Forest
    set_key US-5464 KFF-4897  # Clear Creek State Forest
    set_key US-5465 KFF-4898  # Cornplanter State Forest
    set_key US-5466 KFF-4899  # Delaware State Forest
    set_key US-5467 KFF-4900  # Elk State Forest
    set_key US-5468 KFF-4901  # Forbes State Forest
    set_key US-5469 KFF-4902  # Gallitzin State Forest
    set_key US-5470 KFF-4903  # Loyalsock State Forest
    set_key US-5471 KFF-4904  # Michaux State Forest
    set_key US-5472 KFF-4905  # Moshannon State Forest
    set_key US-5473 KFF-4906  # Pinchot State Forest
    set_key US-5474 KFF-4907  # Rothrock State Forest
    set_key US-5475 KFF-4908  # Sproul State Forest
    set_key US-5476 KFF-4909  # Susquehannock State Forest
    set_key US-5477 KFF-4910  # Tiadaghton State Forest
    set_key US-5478 KFF-4911  # Tioga State Forest
    set_key US-5479 KFF-4912  # Tuscarora State Forest
    set_key US-5480 KFF-4913  # Weiser State Forest
    set_key US-5481 KFF-4914  # William Penn State Forest
    set_key US-5485 KFF-4779  # Harbison State Forest
    set_key US-5486 KFF-4780  # Manchester State Forest
    set_key US-5487 KFF-4781  # Poe Creek State Forest
    set_key US-5488 KFF-4782  # Sand Hills State Forest
    set_key US-5489 KFF-4783  # Wee Tee State Forest
    set_key US-5490 KFF-7186  # Bledsoe State Forest
    set_key US-5491 KFF-6999  # Chickasaw State Forest
    set_key US-5492 KFF-7183  # Chuck Swan State Forest
    set_key US-5493 KFF-7185  # Franklin State Forest
    set_key US-5494 KFF-7192  # John Tully State Forest
    set_key US-5495 KFF-7194  # Lewis State Forest
    set_key US-5496 KFF-7190  # Lone Mountain State Forest
    set_key US-5497 KFF-7193  # Martha Sundquist State Forest
    set_key US-5498 KFF-7184  # Pickett State Forest
    set_key US-5499 KFF-7451  # Prentice Cooper State Forest
    set_key US-5500 KFF-7191  # Scott State Forest
    set_key US-5501 KFF-7187  # Standing Stone State Forest
    set_key US-5502 KFF-7189  # Stewart State Forest
    set_key US-5503 KFF-4844  # Appomattox-Buckingham State Forest
    set_key US-5504 KFF-4845  # Big Woods Wildlife Management Area
    set_key US-5505 KFF-4846  # Bourassa State Forest
    set_key US-5506 KFF-4847  # Browne State Forest
    set_key US-5507 KFF-4848  # Channels State Forest
    set_key US-5509 KFF-4849  # Chilton Woods State Forest
    set_key US-5510 KFF-4850  # Conway-Robinson Memorial State Forest
    set_key US-5511 KFF-4851  # Crawfords State Forest
    set_key US-5512 KFF-4852  # Cumberland State Forest
    set_key US-5513 KFF-6716  # Halpata Tatanaki Preserve State Conservation Area
    set_key US-5514 KFF-4854  # Dragon Run State Forest
    set_key US-5515 KFF-4855  # Hawks State Forest
    set_key US-5516 KFF-4856  # Lesesne State Forest
    set_key US-5517 KFF-4857  # Matthews State Forest
    set_key US-5518 KFF-4858  # Moore's Creek State Forest
    set_key US-5519 KFF-4859  # Niday Place State Forest
    set_key US-5521 KFF-4861  # Paul State Forest
    set_key US-5522 KFF-4862  # Prince Edward-Gallion State Forest
    set_key US-5523 KFF-4863  # Sandy Point State Forest
    set_key US-5524 KFF-6704  # Chito Branch Reserve State Conservation Area
    set_key US-5525 KFF-4864  # Whitney State Forest
    set_key US-5526 KFF-4865  # Zoar State Forest
    set_key US-5530 KFF-7336  # Dorand State Forest
    set_key US-5547 KFF-7337  # Granville Gulf Reservation State Forest
    set_key US-5552 KFF-7338  # Groton State Forest
    set_key US-5563 KFF-7335  # Black Turn Brook State Forest
    set_key US-5582 KFF-4979  # Cabwaylingo State Forest
    set_key US-5583 KFF-4980  # Calvin Price State Forest
    set_key US-5585 KFF-4981  # Coopers Rock State Forest
    set_key US-5586 KFF-4982  # Greenbrier State Forest
    set_key US-5587 KFF-4983  # Kanawha State Forest
    set_key US-5588 KFF-4984  # Kumbrabow State Forest
    set_key US-5589 KFF-4986  # Seneca State Forest
    set_key US-5590 KFF-7106  # Big Cottonwood Wildlife Management Area
    set_key US-5592 KFF-7079  # Blackfoot River Wildlife Management Area
    set_key US-5593 KFF-6974  # Boise River Wildlife Management Area
    set_key US-5594 KFF-7088  # Boundary-Smith Creek Wildlife Management Area
    set_key US-5595 KFF-7019  # Camas Prairie - Centennial Marsh Wildlife Management Area
    set_key US-5596 KFF-7146  # Carey Lake Wildlife Management Area
    set_key US-5597 KFF-6859  # Cartier Slough WMA
    set_key US-5598 KFF-6983  # Cecil D. Andrus Wildlife Management Area
    set_key US-5600 KFF-7014  # Coeur d'Alene River Wildlife Management Area
    set_key US-5602 KFF-6860  # Deer Parks WMA
    set_key US-5603 KFF-7108  # Farragut Wildlife Management Area
    set_key US-5604 KFF-7103  # Fort Boise Wildlife Management Area
    set_key US-5605 KFF-7040  # Georgetown Summit Wildlife Management Area
    set_key US-5606 KFF-7139  # Hagerman Wildlife Management Area
    set_key US-5607 KFF-7022  # Market Lake Wildlife Management Area
    set_key US-5608 KFF-7095  # McArthur Lake Wildlife Management Area
    set_key US-5609 KFF-7131  # Montour Wildlife Management Area
    set_key US-5610 KFF-7086  # Montpelier Wildlife Management Area
    set_key US-5611 KFF-6861  # Mud Lake WMA
    set_key US-5612 KFF-7137  # Niagara Springs Wildlife Management Area
    set_key US-5613 KFF-7132  # Payette River Wildlife Management Area
    set_key US-5614 KFF-7176  # Pend Oreille Wildlife Management Area
    set_key US-5615 KFF-7044  # Portneuf Wildlife Management Area
    set_key US-5618 KFF-6862  # Sand Creek WMA
    set_key US-5619 KFF-6981  # Snow Peak Wildlife Management Area
    set_key US-5620 KFF-7175  # Sterling Wildlife Management Area
    set_key US-5621 KFF-6979  # Tex Creek Wildlife Management Area
    set_key US-5622 KFF-6942  # Niobrara National Wild and Scenic River
    set_key US-5623 KFF-4753  # Minnewaska State Park Preserve
    set_key US-5633 KFF-6090  # Carlsbad State Beach
    set_key US-5634 KFF-4746  # South Carlsbad State Beach
    set_key US-5635 KFF-6257  # Mount Greylock State Reserve
    set_key US-5637 KFF-6419  # Holland State Forest
    set_key US-5638 KFF-6418  # Funk Memorial State Forest
    set_key US-5641 KFF-4620  # Jesse Owens State Park
    set_key US-5644 KFF-4667  # Fisher Grove State Park
    set_key US-5645 KFF-4699  # Spirit Mound Historic Prairie State Park
    set_key US-5647 KFF-7295  # Branched Oak State Recreation Area
    set_key US-5649 KFF-7296  # Pawnee State Recreation Area
    set_key US-5651 KFF-7297  # Olive Creek Lake State Recreation Area
    set_key US-5652 KFF-7298  # Bluestem Lake State Recreation Area
    set_key US-5653 KFF-7299  # Stagecoach Lake State Recreation Area
    set_key US-5654 KFF-7300  # Wagon Train State Recreation Area
    set_key US-5656 KFF-7301  # Flanagan Lake State Recreation Area
    set_key US-5661 NIL-0000  # Bridgeport State Recreation Area (no WWFF)
    set_key US-5670 KFF-6722  # Lake Panasoffkee State Conservation Area
    set_key US-5676 KFF-7302  # Two Rivers State Recreation Area
    set_key US-5694 KFF-6997  # Balsam Lake Mountain Wild State Forest
    set_key US-5696 KFF-6303  # Angeline State Conservation Area
    set_key US-5697 KFF-6306  # Atlanta Wildlife Area
    set_key US-5698 KFF-6314  # Blind Pony State Conservation Area
    set_key US-5699 KFF-5769  # August A. Busch Memorial State Conservation Area
    set_key US-5700 KFF-6348  # Grand Pass State Conservation Area
    set_key US-5701 KFF-6343  # Fountain Grove State Conservation Area
    set_key US-5703 KFF-5707  # Hunnewell Lake State Conservation Area
    set_key US-5704 KFF-6356  # Indian Trail State Conservation Area
    set_key US-5705 KFF-6357  # Lake Paho State Conservation Area
    set_key US-5706 KFF-6365  # Little Dixie Lake State Conservation Area
    set_key US-5707 KFF-6367  # Lost Valley State Fish and Wildlife Area
    set_key US-5708 KFF-6381  # Montrose State Conservation Area
    set_key US-5709 KFF-6383  # Nodaway State Conservation Area
    set_key US-5710 KFF-6391  # Platte Falls State Conservation Area
    set_key US-5711 KFF-6392  # Pony Express Lake State Conservation Area
    set_key US-5712 KFF-6423  # James A. Reed Memorial Wildlife Area
    set_key US-5717 KFF-4713  # Little Jerusalem Badlands State Park
    set_key US-5718 KFF-5198  # Flint Hills Trail State Park
    set_key US-5719 KFF-5622  # Ted Harvey State Conservation Area
    set_key US-5720 KFF-6293  # Tappahanna
    set_key US-5721 KFF-5623  # Norman G Wilder State Wildlife Area
    set_key US-5722 KFF-6291  # McGinnis Pond
    set_key US-5723 KFF-5624  # Milford Neck State Wildlife Area
    set_key US-5724 KFF-6292  # Prime Hook
    set_key US-5725 KFF-6290  # Marshy Hope
    set_key US-5726 KFF-5625  # Old Furnace State Wildlife Area
    set_key US-5727 KFF-5626  # Nanticoke State Wildlife Area
    set_key US-5728 KFF-5627  # Midlands State Wildlife Area
    set_key US-5738 KFF-7266  # Wilson Island State Recreation Area
    set_key US-5741 KFF-7179  # Turtle Mountain State Forest
    set_key US-5742 KFF-7180  # Homen State Forest
    set_key US-5749 NIL-0000  # Kokopelli's Trail National Recreation Area
    set_key US-5751 KFF-4714  # Browns Park BLM Recreation Management Area
    set_key US-5757 KFF-4967  # John Wesley Powell BLM National Conservation Area
    set_key US-5761 NIL-0000  # La Sal Mountain National Forest (UT); WWFF candidates: KFF-4635, KFF-4636
    set_key US-5779 KFF-4727  # Willard Spur Waterfowl Management Area
    set_key US-5793 KFF-4730  # Flaming Gorge National Recreation Area (WY)
    set_key US-5828 KFF-6012  # Dark Canyon BLM Special Recreation Management Area
    set_key US-5843 KFF-6014  # Desolation Canyon BLM Wilderness Area
    set_key US-5847 KFF-6029  # Turtle Canyon BLM Wilderness Area
    set_key US-5856 KFF-6016  # High Uintas USFS Wilderness Area
    set_key US-5857 KFF-6028  # San Rafael Reef Recreation Management Area
    set_key US-5858 KFF-6019  # Mexican Mountain BLM Wilderness Area
    set_key US-5862 KFF-5761  # Sinbad BLM Wild Burro Herd Managemnt Area
    set_key US-5864 KFF-6005  # Big Wild Horse Mesa BLM Wilderness Area
    set_key US-5867 KFF-5760  # San Rafael Swell Recreation Management Area
    set_key US-5868 KFF-4729  # Jurassic BLM National Monument
    set_key US-5877 KFF-4719  # Desert Lake State Waterfowl Management Area
    set_key US-5885 KFF-5758  # Little Wild Horse Canyon TH BLM Recreation Management Area
    set_key US-5888 KFF-5756  # Cold Wash BLM Wilderness Area
    set_key US-5890 KFF-6017  # Horse Valley BLM Wilderness Area
    set_key US-5891 KFF-5757  # Eagle Canyon BLM Wilderness Area
    set_key US-5896 KFF-5759  # Muddy Creek BLM Wild Horse Herd Management Area
    set_key US-5902 KFF-6015  # Devil's Canyon BLM Wilderness Area
    set_key US-5909 KFF-5151  # Woodruff Utah DWR/BLM Wildlife Management Area
    set_key US-5921 KFF-6424  # Anasazi State Park
    set_key US-5922 KFF-6847  # Echo State Park
    set_key US-5923 KFF-5153  # Henefer-Echo UDWR Wildlife Management Area
    set_key US-5930 KFF-4718  # Bicknell Bottoms State Waterfowl Management Area
    set_key US-5933 KFF-5154  # Hardware Ranch Wildlife Management Area
    set_key US-5938 KFF-6023  # Mount Timpanogos USFS Wilderness Area
    set_key US-5941 KFF-6020  # Mount Naomi USFS Wilderness Area
    set_key US-5942 KFF-6022  # Mount Olympus USFS Wilderness Area
    set_key US-5943 KFF-6018  # Lone Peak USFS Wilderness Area
    set_key US-5944 KFF-6030  # Twin Peaks USFS Wilderness Area
    set_key US-5947 KFF-5152  # Middle Fork USFS UDWR Wildlife Management Area
    set_key US-5948 KFF-6021  # Mount Nebo USFS Wilderness Area
    set_key US-5955 KFF-4720  # Farmington Bay State Waterfowl Management Area
    set_key US-5961 NIL-0000  # Paria Canyon - Vermillion Cliffs (UT); WWFF candidates: KFF-6024, KFF-6025
    set_key US-5963 KFF-6031  # Wellsville Mountain USFS Wilderness Area
    set_key US-5967 KFF-4725  # Ogden Bay State Waterfowl Management Area
    set_key US-5968 KFF-4723  # Howard Slough State Waterfowl Management Area
    set_key US-5971 KFF-4722  # Harold S. Crane State Waterfowl Management Area
    set_key US-5973 KFF-4726  # Salt Creek State Waterfowl Management Area
    set_key US-5990 KFF-4721  # Timpie Springs State Waterfowl Management Area
    set_key US-5991 KFF-4715  # Clear Lake State Waterfowl Management Area
    set_key US-5994 KFF-6013  # Deseret Peak USFS Wilderness Area
    set_key US-5998 KFF-4728  # Horseshoe Springs Wildlife Management Area
    set_key US-6009 KFF-4724  # Locomotive Springs State Wildlife Management Area
    set_key US-6017 KFF-6009  # Cedar Mountain BLM Wilderness Area
    set_key US-6018 KFF-6008  # Canaan Mountain BLM Wilderness Area
    set_key US-6035 KFF-6032  # Zion NPS Wilderness Area
    set_key US-6037 KFF-6006  # Blackridge BLM Wilderness Area
    set_key US-6063 KFF-4968  # Red Cliffs BLM Recreation Management Area
    set_key US-6065 KFF-6011  # Cottonwood Forest USFS Wilderness Area
    set_key US-6066 KFF-6026  # Pine Valley Mountain USFS Wilderness Area
    set_key US-6069 KFF-6010  # Cottonwood Canyon BLM Wilderness Area
    set_key US-6088 KFF-6027  # Red Mountain BLM Wilderness Area
    set_key US-6090 NIL-0000  # Beaver Dam Mountain (UT); WWFF candidates: KFF-6003, KFF-6004
    set_key US-6096 KFF-4966  # Beaver Dam Wash National Conservation Area
    set_key US-6108 KFF-7098  # Table Mountain Wildlife Habitat Management Area
    set_key US-6109 KFF-7058  # Springer/Bump Sullivan Wildlife Habitat Management Area
    set_key US-6110 KFF-7143  # Rawhide Wildlife Habitat Management Area
    set_key US-6112 KFF-7148  # Cottonwood Draw Wildlife Habitat Management Area
    set_key US-6114 NIL-0000  # Oregon Trail Ruts State Historic Site
    set_key US-6115 NIL-0000  # Historic Governors' Mansion State Historic Site
    set_key US-6116 KFF-4584  # Thunder Basin National Grassland
    set_key US-6118 KFF-7066  # Tom Thorne/Beth Williams Wildlife Habitat Management Area
    set_key US-6120 NIL-0000  # Ames Monument State Historic Site
    set_key US-6123 KFF-7101  # Forbes/Sheep Mountain Wildlife Habitat Management Area
    set_key US-6126 KFF-6984  # Wick Brothers/Beumee Wildlife Habitat Management Area
    set_key US-6135 KFF-7010  # Pennock Mountain Wildlife Habitat Management Area
    set_key US-6139 KFF-7016  # Bud Love Wildlife Habitat Management Area
    set_key US-6141 KFF-7034  # Morgan Creek Wildlife Habitat Management Area
    set_key US-6145 KFF-7006  # Ed O. Taylor Wildlife Habitat Management Area
    set_key US-6151 KFF-7048  # Amsden Creek Wildlife Habitat Management Area
    set_key US-6152 KFF-7001  # Medicine Lodge Wildlife Habitat Management Area
    set_key US-6154 KFF-6994  # Renner Wildlife Habitat Management Area
    set_key US-6156 KFF-6976  # Red Rim-Grizzly Wildlife Habitat Management Area
    set_key US-6158 KFF-7031  # Kerns Wildlife Habitat Management Area
    set_key US-6161 KFF-5923  # Continental Peak BLM Wild Horse Herd Management Area
    set_key US-6165 KFF-5926  # Triangle BLM Wild Horse Herd Management Area
    set_key US-6170 KFF-6989  # Yellowtail Wildlife Habitat Management Area
    set_key US-6175 KFF-6988  # Sand Mesa Wildlife Habitat Management Area
    set_key US-6179 KFF-7004  # Ocean Lake Wildlife Habitat Management Area
    set_key US-6180 KFF-7091  # Red Canyon Wildlife Habitat Management Area
    set_key US-6198 KFF-5925  # Salt Wells Creek BLM Wild Horse Herd Management Area
    set_key US-6204 KFF-5924  # Little Colorado BLM Wild Horse Herd Management Area
    set_key US-6205 KFF-6992  # Kirk Inberg/Kevin Roy Wildlife Habitat Management Area
    set_key US-6210 KFF-6899  # Teton Wilderness Area
    set_key US-6212 KFF-6998  # Whiskey Basin Wildlife Habitat Management Area
    set_key US-6213 KFF-5927  # White Mountain BLM Wild Horse Herd Management Area
    set_key US-6224 KFF-4545  # Fort Bridger State Historic Site
    set_key US-6226 KFF-6893  # Jedediah Smith Wilderness Area
    set_key US-6227 NIL-0000  # Snake River (WA) National Wild and Scenic River; WWFF candidates: KFF-7229, KFF-7230, KFF-7231
    set_key US-6229 KFF-7136  # South Park Wildlife Habitat Management Area
    set_key US-6233 KFF-7064  # Greys River Wildlife Habitat Management Area
    set_key US-6244 KFF-7332  # Flat Rock Cedar Glade State Natural Area
    set_key US-6245 KFF-7418  # Ghost River State Natural Area
    set_key US-6246 KFF-7419  # Hampton Creek Cove State Natural Area
    set_key US-6249 KFF-7423  # House Mountain State Natural Area
    set_key US-6252 KFF-7426  # Laurel Snow State Natural Area
    set_key US-6253 KFF-7427  # Lost Creek State Natural Area
    set_key US-6255 KFF-7429  # May Prairie State Natural Area
    set_key US-6260 KFF-7450  # Piney Falls State Natural Area
    set_key US-6261 KFF-7452  # Pogue Creek Canyon State Natural Area
    set_key US-6265 KFF-7453  # Rugby State Natural Area
    set_key US-6266 KFF-7454  # Savage Gulf State Natural Area
    set_key US-6270 KFF-7457  # Stinging Fork Falls State Natural Area
    set_key US-6271 KFF-7458  # Sunk Lake State Natural Area
    set_key US-6272 KFF-7462  # Twin Arches State Natural Area
    set_key US-6275 KFF-7463  # Walls of Jericho State Natural Area
    set_key US-6281 KFF-5362  # Loxahatchee National Wild and Scenic River
    set_key US-6282 KFF-5176  # Newnans Lake State Forest
    set_key US-6283 KFF-5181  # Plank Road State Forest
    set_key US-6284 KFF-5363  # Atlantic Ridge Preserve State Park
    set_key US-6285 KFF-5178  # Peace River State Forest
    set_key US-6286 KFF-5227  # Andrews Wildlife Management Area
    set_key US-6287 KFF-5228  # Apalachee Wildlife Management Area
    set_key US-6288 KFF-5229  # Apalachicola River Wildlife Area
    set_key US-6289 KFF-5230  # Aucilla Wildlife Management Area
    set_key US-6290 KFF-5232  # Bell Ridge Longleaf Wildlife Area
    set_key US-6291 KFF-5233  # Fred C. Babcock/Cecil M. Webb Wildlife Management Area
    set_key US-6292 KFF-5234  # Big Bend Wildlife Management Area
    set_key US-6293 KFF-5235  # Box-R Wildlife Management Area
    set_key US-6294 KFF-5236  # Branan Field Wildlife Area
    set_key US-6295 KFF-5237  # Caravelle Ranch Wildlife Management Area
    set_key US-6296 KFF-5238  # Chassahowitzka Wildlife Management Area
    set_key US-6297 KFF-5239  # Chinsegut Wildlife Area
    set_key US-6298 KFF-5240  # Crooked Lake Wildlife Area
    set_key US-6299 KFF-5241  # Dinner Island Ranch Wildlife Management Area
    set_key US-6300 KFF-5242  # Escribano Point Wildlife Management Area
    set_key US-6301 KFF-5243  # Everglades and Francis S. Taylor Wildlife Management Area
    set_key US-6302 KFF-5244  # Fisheating Creek Wildlife Management Area
    set_key US-6303 KFF-5245  # Florida Keys Wildlife Area
    set_key US-6304 KFF-5246  # Fort White Wildlife Area
    set_key US-6305 KFF-5247  # Guana River Wildlife Management Area
    set_key US-6306 KFF-5248  # Half Moon Wildlife Management Area
    set_key US-6307 KFF-5249  # Herky Huffman/Bull Creek Wildlife Management Area
    set_key US-6308 KFF-5250  # Hickey Creek Wildlife Management Area
    set_key US-6309 KFF-5251  # Hilochee Wildlife Management Area
    set_key US-6310 KFF-5252  # Holey Land Wildlife Management Area
    set_key US-6311 KFF-5253  # J. W. Corbett Wildlife Management Area
    set_key US-6312 KFF-5254  # Joe Budd Wildlife Management Area
    set_key US-6313 KFF-5255  # John C. and Mariana Jones/Hungryland Wildlife Area
    set_key US-6314 KFF-5256  # L. Kirk Edwards Wildlife Area
    set_key US-6315 KFF-5257  # Lafayette Forest Wildlife Area
    set_key US-6316 KFF-5258  # Little Gator Creek Wildlife Area
    set_key US-6317 KFF-5259  # Moody Branch Wildlife Area
    set_key US-6318 KFF-5260  # Okaloacoochee Slough Wildlife Management Area
    set_key US-6319 KFF-5261  # Perry Oldenburg Wildlife Area
    set_key US-6320 KFF-5262  # Platt Branch Wildlife Area
    set_key US-6321 KFF-5263  # Rotenberger Wildlife Management Area
    set_key US-6322 KFF-5264  # Salt Lake Wildlife Management Area
    set_key US-6323 KFF-5265  # Spirit-of-the-Wild Wildlife Management Area
    set_key US-6324 KFF-5266  # Split Oak Forest Wildlife Area
    set_key US-6325 KFF-5267  # Suwannee Ridge Wildlife Area
    set_key US-6326 KFF-5268  # T.M. Goodwin Wildlife Management Area
    set_key US-6327 KFF-5269  # Tenoroc Wildlife Area
    set_key US-6328 KFF-5270  # Three Lakes Wildlife Management Area
    set_key US-6329 KFF-5271  # Tosohatchee Wildlife Management Area
    set_key US-6330 KFF-5272  # Triple N Ranch Wildlife Management Area
    set_key US-6331 KFF-5273  # Watermelon Pond Wildlife Area
    set_key US-6333 KFF-4807  # Fort Gibson Wildlife Management Area
    set_key US-6334 KFF-4795  # Beaver River Wildlife Management Area
    set_key US-6339 KFF-4794  # Atoka Wildlife Management Area
    set_key US-6340 KFF-4796  # Black Kettle Wildlife Management Area
    set_key US-6341 KFF-4797  # Broken Bow Wildlife Management Area
    set_key US-6342 KFF-4798  # Camp Gruber Wildlife Management Area
    set_key US-6343 KFF-4799  # Canton Wildlife Management Area
    set_key US-6344 KFF-2776  # Cherokee Wildlife Management Area
    set_key US-6345 KFF-4801  # Cookson Wildlife Management Area
    set_key US-6346 KFF-4802  # Hal and Fern Cooper Wildlife Management Area
    set_key US-6347 KFF-4803  # Copan Wildlife Management Area
    set_key US-6348 KFF-4804  # Cross Timbers Wildlife Management Area
    set_key US-6349 KFF-4805  # Deep Fork Wildlife Management Area
    set_key US-6350 KFF-4806  # Eufaula Wildlife Management Area
    set_key US-6351 KFF-4808  # Hackberry Flat Wildlife Management Area
    set_key US-6352 KFF-4809  # Honobia Creek Wildlife Management Area
    set_key US-6353 KFF-4810  # Hugo Wildlife Management Area
    set_key US-6354 KFF-4811  # James Collins Wildlife Management Area
    set_key US-6355 KFF-4812  # Kaw Wildlife Management Area
    set_key US-6356 KFF-4813  # Keystone Wildlife Management Area
    set_key US-6357 KFF-4814  # Lexington Wildlife Management Area
    set_key US-6358 KFF-4815  # Love Valley Wildlife Management Area
    set_key US-6359 KFF-4816  # McClellan-Kerr Wildlife Management Area
    set_key US-6360 KFF-4817  # McCurtain County Wildlife Management Area
    set_key US-6361 KFF-4818  # McGee Creek Wildlife Management Area
    set_key US-6362 KFF-4819  # Mountain Park Wildlife Management Area
    set_key US-6363 KFF-4820  # Okmulgee Wildlife Management Area
    set_key US-6364 KFF-4821  # Oologah Wildlife Management Area
    set_key US-6365 KFF-4822  # Osage Wildlife Management Area
    set_key US-6366 KFF-4823  # Ouachita Leflore Unit Wildlife Management Area
    set_key US-6367 KFF-4824  # Ouachita McCurtain Unit Wildlife Management Area
    set_key US-6368 KFF-4825  # Packsaddle Wildlife Management Area
    set_key US-6369 KFF-4826  # Pine Creek Wildlife Management Area
    set_key US-6370 KFF-4827  # Pushmataha Wildlife Management Area
    set_key US-6371 KFF-4828  # Red Slough Wildlife Management Area
    set_key US-6372 KFF-4829  # Rita Blanca Wildlife Management Area
    set_key US-6373 KFF-4830  # Robbers Cave Wildlife Management Area
    set_key US-6374 KFF-4831  # Sandy Sanders Wildlife Management Area
    set_key US-6375 KFF-4832  # Skiatook Wildlife Management Area
    set_key US-6376 KFF-2805  # Spavinaw Wildlife Management Area
    set_key US-6377 KFF-4835  # Three Rivers Wildlife Management Area
    set_key US-6378 KFF-4834  # Texoma Washita Arm Wildlife Management Area
    set_key US-6379 KFF-4836  # Waurika Wildlife Management Area
    set_key US-6380 KFF-4837  # Wister Wildlife Management Area
    set_key US-6381 KFF-5569  # Hickory Creek Wildlife Management Area
    set_key US-6382 KFF-5009  # Harriet Tubman Underground Railroad State Park
    set_key US-6383 KFF-5010  # Matapeake State Park
    set_key US-6384 KFF-4766  # Pocomoke River State Park
    set_key US-6385 KFF-5008  # Bohemia River State Park
    set_key US-6387 KFF-5537  # Fair Hill State Natural Area
    set_key US-6391 KFF-5538  # Merkle Wildlife Sanctuary State Natural Area
    set_key US-6392 KFF-5539  # Monocacy River Natural Resources Management Area State Natural Area
    set_key US-6393 KFF-5534  # Morgan Run State Natural Area
    set_key US-6394 KFF-5011  # Sang Run State Park
    set_key US-6395 KFF-5540  # Sassafras Natural Resources Management Area State Natural Area
    set_key US-6396 KFF-5533  # Soldier's Delight National Environmental Area State Natural Area
    set_key US-6397 KFF-5013  # Wolf Den Run State Park
    set_key US-6398 KFF-5541  # Woodmont State Natural Area
    set_key US-6399 KFF-5542  # Wye Island State Conservation Area
    set_key US-6400 KFF-5535  # Youghiogheny Wild River State Natural Area
    set_key US-6433 KFF-7505  # White Clay Creek State Preserve
    set_key US-6434 KFF-6968  # Champoeg State Park
    set_key US-6435 KFF-6840  # Emigrant Springs State Park
    set_key US-6444 KFF-6705  # Conner Preserve State Conservation Area
    set_key US-6445 KFF-7274  # St. Tammany Wildlife Refuge
    set_key US-6446 KFF-4748  # Brannan Island State Recreation Area
    set_key US-6447 KFF-4747  # Corona del Mar State Beach
    set_key US-6448 KFF-4745  # William Randolph Hearst Memorial State Beach
    set_key US-6449 KFF-4744  # Little River State Beach
    set_key US-6450 KFF-4743  # Gray Whale Cove State Beach
    set_key US-6451 KFF-4742  # Casper Headlands State Beach
    set_key US-6452 KFF-4741  # Carmel River State Beach
    set_key US-6453 KFF-4740  # McGrath State Beach
    set_key US-6454 KFF-4739  # El Capitan State Beach
    set_key US-6461 KFF-5293  # Spruce Run State Recreation Area
    set_key US-6463 KFF-5366  # Garden Island State Recreation Area
    set_key US-6464 KFF-5364  # Big Bog State Recreation Area
    set_key US-6465 KFF-5367  # Greenleaf State Recreation Area
    set_key US-6466 KFF-5365  # Cuyuna Country State Recreation Area
    set_key US-6467 KFF-5311  # Mad Horse Creek Wildlife Management Area
    set_key US-6470 KFF-6323  # Burr Oak Woods State Conservation Area
    set_key US-6475 KFF-6358  # Kendzora State Conservation Area
    set_key US-6476 KFF-6328  # Cooley Lake State Conservation Area
    set_key US-6477 KFF-6302  # Amarugia Highlands State Conservation Area
    set_key US-6478 KFF-6371  # Maple Leaf Lake State Conservation Area
    set_key US-6479 KFF-6331  # Crooked River State Conservation Area
    set_key US-6480 KFF-6351  # Poague Haysler State Conservation Area
    set_key US-6481 KFF-6350  # Harmony Mission Lake State Conservation Area
    set_key US-6482 KFF-6402  # Schell-Osage State Conservation Area
    set_key US-6483 KFF-6360  # King Lake State Conservation Area
    set_key US-6484 KFF-6361  # Lamine River State Conservation Area
    set_key US-6486 KFF-6309  # Ben Branch Lake State Conservation Area
    set_key US-6487 KFF-6304  # Apple Creek State Conservation Area
    set_key US-6488 KFF-6336  # Duck Creek State Conservation Area
    set_key US-6489 KFF-5777  # Howell Island State Conservation Area
    set_key US-6490 KFF-6298  # Daniel Boone State Conservation Area
    set_key US-6491 KFF-6388  # Peck Ranch State Conservation Area
    set_key US-6492 KFF-5782  # Weldon Spring State Conservation Area
    set_key US-6493 KFF-6346  # General Watkins State Conservation Area
    set_key US-6494 KFF-6327  # Columbia Bottom State Conservation Area
    set_key US-6495 KFF-6363  # Little Black State Conservation Area
    set_key US-6496 KFF-6385  # Otter Slough State Conservation Area
    set_key US-6497 KFF-6329  # Coon Island State Conservation Area
    set_key US-6498 KFF-6332  # Current River State Conservation Area
    set_key US-6499 KFF-6355  # Huzzah State Conservation Area
    set_key US-6500 KFF-6377  # Meramec State Conservation Area
    set_key US-6502 KFF-6326  # Castor River State Conservation Area
    set_key US-6503 KFF-6369  # Magnolia Hollow State Conservation Area
    set_key US-6504 KFF-6378  # Millstream Gardens State Conservation Area
    set_key US-6505 NIL-0000  # Diggs-Marshall State Conservation Area; WWFF candidates: KFF-5779, KFF-6374
    set_key US-6506 KFF-6412  # Whetstone Creek State Conservation Area
    set_key US-6507 KFF-6395  # Rebel's Cove State Conservation Area
    set_key US-6509 KFF-6387  # Painted Rock State Conservation Area
    set_key US-6510 KFF-6317  # Bois D'Arc State Conservation Area
    set_key US-6511 KFF-6398  # Rocky Fork Lakes State Conservation Area
    set_key US-6512 KFF-5778  # Locust Creek State Conservation Area
    set_key US-6513 KFF-6393  # Poosey State Conservation Area
    set_key US-6514 KFF-6310  # Big Buffalo Creek State Conservation Area
    set_key US-6515 KFF-6316  # Bob Brown State Conservation Area
    set_key US-6516 KFF-6370  # Manito Lake State Conservation Area
    set_key US-6517 KFF-6333  # Diana Bend State Conservation Area
    set_key US-6518 KFF-6340  # Fiery Fork State Conservation Area
    set_key US-6519 KFF-6394  # Prairie Home State Conservation Area
    set_key US-6520 KFF-6349  # Grand Trace State Conservation Area
    set_key US-6521 KFF-6405  # Shawnee Trail State Conservation Area
    set_key US-6522 KFF-6339  # Emmett and Leah Seat Memorial State Conservation Area
    set_key US-6523 KFF-6409  # Thurnau State Conservation Area
    set_key US-6524 KFF-6337  # Eagle Bluffs State Conservation Area
    set_key US-6525 KFF-6311  # Bilby Ranch Lake State Conservation Area
    set_key US-6526 KFF-6399  # Rudolf Bennitt State Conservation Area
    set_key US-6528 KFF-6362  # Lead Mine State Conservation Area
    set_key US-6529 KFF-6930  # Truman Reservoir Lands
    set_key US-6531 KFF-5708  # Deer Ridge State Conservation Area
    set_key US-6533 KFF-4869  # Alabama Creek Wildlife Management Area
    set_key US-6534 KFF-5543  # Alazan Bayou Wildlife Management Area
    set_key US-6535 KFF-4870  # Angelina-Neches/Dam B Wildlife Management Area
    set_key US-6537 KFF-4871  # Bannister Wildlife Management Area
    set_key US-6539 KFF-5544  # Big Lake Bottom Wildlife Management Area
    set_key US-6540 KFF-4872  # Black Gap Wildlife Management Area
    set_key US-6542 KFF-4873  # Caddo Lake Wildlife Management Area
    set_key US-6548 KFF-4874  # Chaparral Wildlife Management Area
    set_key US-6550 KFF-4875  # Cooper Wildlife Management Area
    set_key US-6554 KFF-4876  # Elephant Mountain Wildlife Management Area
    set_key US-6562 KFF-4877  # Gene Howe Wildlife Management Area
    set_key US-6563 KFF-4878  # Guadalupe Delta Wildlife Management Area
    set_key US-6564 KFF-4879  # Gus Engeling Wildlife Management Area
    set_key US-6565 KFF-4880  # J.D. Murphree Wildlife Management Area
    set_key US-6566 KFF-5545  # James E. Daughtrey Wildlife Management Area
    set_key US-6567 KFF-4881  # Justin Hurst Wildlife Management Area
    set_key US-6568 KFF-5905  # Keechi Creek Wildlife Management Area
    set_key US-6569 KFF-4882  # Kerr Wildlife Management Area
    set_key US-6572 KFF-5546  # Las Palomas , Lower Rio Grande Valley Units Wildlife Management Area
    set_key US-6574 KFF-4883  # Lower Neches Wildlife Management Area
    set_key US-6576 KFF-4884  # Mad Island Wildlife Management Area
    set_key US-6578 KFF-4885  # Mason Mountain Wildlife Management Area
    set_key US-6579 KFF-4886  # Matador Wildlife Management Area
    set_key US-6580 KFF-5547  # Matagorda Island Wildlife Management Area
    set_key US-6584 KFF-4887  # Moore Plantation Wildlife Management Area
    set_key US-6585 KFF-5548  # Muse Wildlife Management Area
    set_key US-6586 KFF-5549  # Nannie M. Stringfellow Wildlife Management Area
    set_key US-6589 KFF-5550  # North Toledo Bend Wildlife Management Area
    set_key US-6590 KFF-4888  # Old Sabine Bottom Wildlife Management Area
    set_key US-6591 KFF-4889  # Pat Mayse Wildlife Management Area
    set_key US-6596 KFF-4890  # Richland Creek Wildlife Management Area
    set_key US-6597 NIL-0000  # Rio Grande National Wild and Scenic River (TX); WWFF candidates: KFF-5903, KFF-5904
    set_key US-6605 KFF-5552  # Tawakoni Wildlife Management Area
    set_key US-6609 KFF-4564  # Pinelands Preserve National Conservation Area
    set_key US-6610 KFF-5907  # Welder Flats Wildlife Management Area
    set_key US-6611 KFF-4892  # White Oak Creek Wildlife Management Area
    set_key US-6615 KFF-5053  # Allegan State Game Land
    set_key US-6617 KFF-5054  # Au Train Basin Wildlife Management Area
    set_key US-6618 KFF-5376  # Backus Creek State Game Land
    set_key US-6620 KFF-5055  # Baraga Plains Wildlife Management Area
    set_key US-6621 KFF-5056  # Barry State Game Land
    set_key US-6623 KFF-5057  # Beaver Islands Wildlife Management Area
    set_key US-6624 KFF-5928  # Bentley Marsh Flooding Wildlife Management Area
    set_key US-6625 KFF-6425  # Betsie River State Game Land
    set_key US-6627 KFF-5377  # Black Creek Flooding Wildlife Management Area
    set_key US-6629 KFF-5058  # Blind Sucker River Flooding Wildlife Management Area
    set_key US-6630 KFF-6434  # Blomgren's Marsh Flooding Wildlife Management Area
    set_key US-6632 KFF-6435  # Bluff Creek Wildlife Management Area
    set_key US-6639 KFF-6727  # Potts Preserve State Conservation Area
    set_key US-6640 KFF-5929  # Cannonsburg State Game Land
    set_key US-6641 KFF-5930  # Cass City State Game Land
    set_key US-6643 KFF-6426  # Chelsea State Game Land
    set_key US-6647 KFF-5931  # Connors Marsh Wildlife Management Area
    set_key US-6648 KFF-5948  # Cornish State Game Land
    set_key US-6650 KFF-5378  # Crane Pond State Game Land
    set_key US-6651 KFF-5379  # Crow Island State Game Land
    set_key US-6652 KFF-5932  # Cusino Wildlife Management Area
    set_key US-6653 KFF-5380  # Dansville State Game Land
    set_key US-6655 KFF-5933  # Dead Stream Flooding Wildlife Management Area
    set_key US-6657 KFF-5059  # Deford State Game Land
    set_key US-6659 KFF-6436  # Denton Creek Flooding Wildlife Management Area
    set_key US-6660 KFF-6437  # Devils Lake Flooding Wildlife Management Area
    set_key US-6661 KFF-5381  # Dingman Marsh Flooding Wildlife Management Area
    set_key US-6662 KFF-5934  # Dog Lake Flooding Wildlife Management Area
    set_key US-6663 KFF-5382  # Dollarville Flooding Wildlife Management Area
    set_key US-6666 KFF-5196  # Edger Waterfowl National Wildlife Management Area
    set_key US-6667 KFF-5383  # Edmore State Game Land
    set_key US-6669 KFF-5384  # Erie State Game Land
    set_key US-6672 KFF-5385  # Fish Point State Wildlife Area
    set_key US-6673 KFF-5060  # Flat River State Game Land
    set_key US-6677 KFF-5386  # French Farm Lake Flooding Wildlife Management Area
    set_key US-6679 KFF-6427  # Fulton State Game Land
    set_key US-6680 KFF-5935  # Gagetown State Game Land
    set_key US-6683 KFF-5936  # Gladwin State Game Land
    set_key US-6688 KFF-5387  # Gourdneck State Game Land
    set_key US-6691 KFF-5938  # Grass Lake Flooding Wildlife Management Area
    set_key US-6694 KFF-5061  # Gratiot-Saginaw State Game Land
    set_key US-6696 KFF-5388  # Gregory State Game Land
    set_key US-6699 KFF-6438  # Hancock Creek Flooding Wildlife Management Area
    set_key US-6701 KFF-5062  # Haymarsh Lake State Game Land
    set_key US-6702 KFF-5389  # Hayward Lake to North Lake Floodings Wildlife Management Area
    set_key US-6706 KFF-5390  # Horseshoe Lake State Game Land
    set_key US-6709 KFF-5063  # Houghton Lake Wildlife Management Area
    set_key US-6710 KFF-6428  # Hubbard Lake State Game Land
    set_key US-6711 KFF-5391  # Kawkawlin Creek Flooding Wildlife Management Area
    set_key US-6713 KFF-5193  # Kinney Waterfowl National Wildlife Management Area
    set_key US-6718 KFF-5392  # Langston State Game Land
    set_key US-6719 KFF-5064  # Lapeer State Game Land
    set_key US-6723 KFF-5393  # Little Fox River Flooding / Stanley Lake Wildlife Management Area
    set_key US-6725 KFF-5394  # Lost Nation State Game Land
    set_key US-6726 KFF-5194  # Malan Waterfowl National Wildlife Management Area
    set_key US-6727 KFF-5395  # Manistee River State Game Land
    set_key US-6730 KFF-5065  # Maple River State Game Land
    set_key US-6732 KFF-6439  # Marsh Creek / Beaver Lake Flooding Wildlife Management Area
    set_key US-6733 KFF-5066  # Martiny Lake State Game Land
    set_key US-6735 KFF-5396  # Middleville State Game Land
    set_key US-6736 KFF-5067  # Minden City State Game Land
    set_key US-6737 KFF-5939  # Molasses River Flooding No 1 Wildlife Management Area
    set_key US-6739 KFF-5068  # Munuscong Bay Wildlife Management Area
    set_key US-6740 KFF-5397  # Murphy Lake State Game Land
    set_key US-6741 KFF-5069  # Muskegon State Game Land
    set_key US-6743 KFF-5398  # Nayanquing Point Wildlife Management Area
    set_key US-6746 KFF-5399  # Oak Grove State Game Land
    set_key US-6750 KFF-5940  # O'Neal Lake Flooding Wildlife Management Area
    set_key US-6751 KFF-6429  # Onsted State Game Land
    set_key US-6752 KFF-5941  # Osceola-Missaukee Grasslands State Game Land
    set_key US-6753 KFF-5400  # Pentwater River State Game Land
    set_key US-6755 KFF-6430  # Petersburg State Game Land
    set_key US-6757 KFF-6431  # Petobego State Game Land
    set_key US-6760 KFF-5949  # Pointe Aux Peaux State Wildlife Area
    set_key US-6761 KFF-5070  # Pointe Mouillee State Game Land
    set_key US-6762 KFF-5071  # Port Huron State Game Land
    set_key US-6763 KFF-6440  # Portage Marsh Wildlife Management Area
    set_key US-6764 KFF-5401  # Portland State Game Land
    set_key US-6765 KFF-5402  # Potagannissing Flooding Wildlife Management Area
    set_key US-6766 KFF-5403  # Quanicassee State Wildlife Area
    set_key US-6767 KFF-5942  # Rainy River Flooding Wildlife Management Area
    set_key US-6769 KFF-5404  # Robinson Creek Flooding Wildlife Management Area
    set_key US-6770 KFF-5072  # Rogue River State Game Land
    set_key US-6771 KFF-5405  # Rose Lake State Game Land
    set_key US-6772 KFF-5406  # Rush Lake State Game Land
    set_key US-6775 KFF-6441  # Sand River/Jeske Flooding Wildlife Management Area
    set_key US-6776 KFF-5943  # Sandusky State Game Land
    set_key US-6777 KFF-5944  # Sanilac State Game Land
    set_key US-6778 KFF-6432  # Saranac-Lowell State Game Land
    set_key US-6780 KFF-5195  # Schoonover Waterfowl National Wildlife Management Area
    set_key US-6781 KFF-5407  # Sharonville State Game Land
    set_key US-6782 KFF-5073  # Shiawassee River State Game Land
    set_key US-6783 KFF-5408  # Skegemog Lake State Wildlife Area
    set_key US-6784 KFF-6433  # Somerset S State Game Land
    set_key US-6787 KFF-5074  # St. Clair Flats State Wildlife Area
    set_key US-6789 KFF-5409  # St. John's Marsh State Wildlife Area
    set_key US-6790 KFF-5410  # Stanton State Game Land
    set_key US-6791 KFF-5945  # Stoney Creek Flooding Wildlife Management Area
    set_key US-6793 KFF-5075  # Sturgeon River Sloughs Wildlife Management Area
    set_key US-6795 KFF-5411  # Three Rivers State Game Land
    set_key US-6796 KFF-5412  # Tobico Marsh State Recreation Area
    set_key US-6797 KFF-5946  # Tomahawk Creek Flooding Wildlife Management Area
    set_key US-6798 KFF-6442  # Townline Creek Flooding Wildlife Management Area
    set_key US-6799 KFF-5076  # Tuscola State Game Land
    set_key US-6800 KFF-5947  # Unadilla State Wildlife Area
    set_key US-6801 KFF-5413  # Vassar State Game Land
    set_key US-6802 KFF-5077  # Verona State Game Land
    set_key US-6803 KFF-5414  # Vestaburg State Game Land
    set_key US-6804 KFF-5415  # Waterloo Unit State Game Land
    set_key US-6806 KFF-5416  # Wigwam Bay State Wildlife Area
    set_key US-6807 KFF-5417  # Wildfowl Bay State Wildlife Area
    set_key US-6857 KFF-5331  # American Legion State Forest
    set_key US-6859 KFF-5335  # Enders State Forest
    set_key US-6860 KFF-5692  # Ferry Landing State Park
    set_key US-6862 KFF-6819  # Horse Guard
    set_key US-6863 KFF-5337  # James L. Goodwin State Forest
    set_key US-6865 KFF-5345  # Nathan Hale State Forest
    set_key US-6866 KFF-5347  # Nehantic State Forest
    set_key US-6867 KFF-5350  # Nye Holman State Forest
    set_key US-6869 KFF-5354  # Peoples State Forest
    set_key US-6870 KFF-6821  # Quinebaug Lake
    set_key US-6871 KFF-6822  # Rocky Glen
    set_key US-6873 KFF-6824  # Stoddard Hill
    set_key US-6874 KFF-5359  # Tunxis State Forest
    set_key US-6877 KFF-4915  # Yadkin River State Game Land
    set_key US-6878 KFF-4916  # Alligator River State Game Land
    set_key US-6879 KFF-4917  # Angola Bay State Game Land
    set_key US-6880 KFF-5274  # Bachelor Bay State Game Land
    set_key US-6881 KFF-5275  # Bertie County State Game Land
    set_key US-6882 KFF-6265  # Bladen Lakes State Game Land
    set_key US-6883 KFF-6266  # Brinkleyville State Game Land
    set_key US-6884 KFF-6613  # Buckhorn State Game Land
    set_key US-6885 KFF-4918  # Buckridge State Game Land
    set_key US-6886 KFF-4919  # Buffalo Cove State Game Land
    set_key US-6887 KFF-6614  # Bullard and Branch Hunting Preserve State Game Land
    set_key US-6888 KFF-4920  # Butner-Falls of the Neuse State Game Land
    set_key US-6889 KFF-6267  # Buxton Woods State Game Land
    set_key US-6890 KFF-4921  # Cape Fear River Wetlands State Game Land
    set_key US-6891 KFF-4922  # Carteret County State Game Land
    set_key US-6892 KFF-5276  # Chatham State Game Land
    set_key US-6894 KFF-4923  # Chowan Swamp State Game Land
    set_key US-6895 KFF-5277  # Cold Mountain State Game Land
    set_key US-6896 KFF-4924  # Columbus County State Game Land
    set_key US-6897 KFF-6268  # Croatan State Game Land
    set_key US-6899 KFF-6269  # Dan River State Game Land
    set_key US-6900 KFF-4926  # Dare State Game Land
    set_key US-6901 KFF-5278  # Dover Bay State Game Land
    set_key US-6902 KFF-4792  # Dupont State Game Land
    set_key US-6903 KFF-6271  # Elk Knob State Game Land
    set_key US-6904 KFF-4927  # Embro State Game Land
    set_key US-6905 KFF-4928  # Goose Creek State Game Land
    set_key US-6906 KFF-4929  # Green River State Game Land
    set_key US-6907 KFF-4930  # Green Swamp State Game Land
    set_key US-6908 KFF-4931  # Gull Rock State Game Land
    set_key US-6909 KFF-4932  # Harris State Game Land
    set_key US-6910 KFF-6272  # Headwaters State Game Land
    set_key US-6911 KFF-6615  # Hill Farm State Game Land
    set_key US-6912 KFF-4933  # Holly Shelter State Game Land
    set_key US-6913 KFF-5279  # Hyco State Game Land
    set_key US-6914 KFF-6273  # J Morgan Futch State Game Land
    set_key US-6915 KFF-4934  # Johns River State Game Land
    set_key US-6916 KFF-4935  # Jordan State Game Land
    set_key US-6917 KFF-4936  # Juniper Creek State Game Land
    set_key US-6918 KFF-6274  # Kerr Scott State Game Land
    set_key US-6919 KFF-6275  # Lantern Acres State Game Land
    set_key US-6920 KFF-6276  # Lee State Game Land
    set_key US-6921 KFF-6277  # Light Ground Pocosin State Game Land
    set_key US-6923 KFF-6278  # Lower Fishing Creek State Game Land
    set_key US-6924 KFF-4937  # Lower Roanoke River State Game Land
    set_key US-6925 KFF-4938  # Mayo State Game Land
    set_key US-6926 KFF-5280  # Mitchell River State Game Land
    set_key US-6927 KFF-4939  # Nantahala State Game Land
    set_key US-6928 KFF-5281  # Needmore State Game Land
    set_key US-6929 KFF-5282  # Neuse River State Game Land
    set_key US-6930 KFF-6279  # New Lake State Game Land
    set_key US-6931 KFF-6280  # Nicholson Creek State Game Land
    set_key US-6932 KFF-4940  # North River State Game Land
    set_key US-6933 KFF-5283  # Northwest River Marsh State Game Land
    set_key US-6934 KFF-5284  # Pee Dee River State Game Land
    set_key US-6935 KFF-6281  # Perkins State Game Land
    set_key US-6937 KFF-6282  # Pisgah WRC State Game Land
    set_key US-6938 KFF-5285  # Pond Mountain State Game Land
    set_key US-6940 KFF-4925  # Bailey-Caswell State Game Land
    set_key US-6941 KFF-5286  # Rendezvous Mountain State Game Land
    set_key US-6942 KFF-6618  # Rhodes Pond State Game Land
    set_key US-6944 KFF-5287  # Rockfish Creek State Game Land
    set_key US-6945 KFF-6619  # Rocky Run State Game Land
    set_key US-6946 KFF-6620  # Sampson State Game Land
    set_key US-6947 KFF-4941  # Sandhills State Game Land
    set_key US-6948 KFF-6283  # Sandy Creek State Game Land
    set_key US-6949 KFF-5288  # Sandy Mush State Game Land
    set_key US-6950 KFF-6284  # Second Creek State Game Land
    set_key US-6951 KFF-4942  # Shocco Creek State Game Land
    set_key US-6952 KFF-4943  # South Mountains State Game Land
    set_key US-6953 KFF-5289  # Stones Creek State Game Land
    set_key US-6954 KFF-4944  # Suggs Mill Pond State Game Land
    set_key US-6955 KFF-6285  # Sutton Lake State Game Land
    set_key US-6956 KFF-6622  # Tar River State Game Land
    set_key US-6957 KFF-6286  # Texas Plantation State Game Land
    set_key US-6958 KFF-4945  # Thurmond Chatham State Game Land
    set_key US-6959 KFF-4946  # Tillery State Game Land
    set_key US-6960 KFF-4947  # Toxaway State Game Land
    set_key US-6961 KFF-4948  # Upper Roanoke River State Game Land
    set_key US-6962 KFF-4949  # Uwharrie State Game Land
    set_key US-6963 KFF-6287  # Vance State Game Land
    set_key US-6964 KFF-5290  # Voice of America State Game Land
    set_key US-6965 KFF-5291  # White Oak River State Game Land
    set_key US-6966 KFF-5292  # Whitehall Plantation State Game Land
    set_key US-6967 KFF-6288  # William H Silver State Game Land
    set_key US-6987 KFF-6844  # Cocumcussoc State Park
    set_key US-6996 KFF-5660  # Cecil H. Underwood Wildlife Management Area
    set_key US-6998 KFF-5663  # Cross Creek Wildlife Management Area
    set_key US-7000 KFF-5667  # Hillcrest Wildlife Management Area
    set_key US-7002 KFF-5671  # Lewis Wetzel Wildlife Management Area
    set_key US-7005 KFF-5676  # Pleasant Creek Wildlife Management Area
    set_key US-7007 KFF-5682  # Snake Hill Wildlife Management Area
    set_key US-7010 KFF-5651  # Allegheny Wildlife Management Area
    set_key US-7013 KFF-5675  # Nathaniel Mountain Wildlife Management Area
    set_key US-7015 KFF-5680  # Short Mountain Wildlife Management Area
    set_key US-7016 KFF-5681  # Sleepy Creek Wildlife Management Area
    set_key US-7021 KFF-5654  # Becky Creek Wildlife Management Area
    set_key US-7023 KFF-5659  # Burnsville Lake Wildlife Management Area
    set_key US-7024 KFF-5665  # Elk River Wildlife Management Area
    set_key US-7026 KFF-5669  # Huttonsville Wildlife Management Area
    set_key US-7029 KFF-5683  # Stonecoal Lake Wildlife Management Area
    set_key US-7030 KFF-5684  # Stonewall Jackson Lake Wildlife Management Area
    set_key US-7031 KFF-5685  # Summersville Lake Wildlife Management Area
    set_key US-7033 KFF-5689  # Wallback Wildlife Management Area
    set_key US-7034 KFF-5653  # Anawalt Lake Wildlife Management Area
    set_key US-7036 KFF-5656  # Beury Mountain Wildlife Management Area
    set_key US-7037 KFF-5658  # Bluestone Lake Wildlife Management Area
    set_key US-7039 KFF-5673  # Meadow River Wildlife Management Area
    set_key US-7041 KFF-5677  # Plum Orchard Lake Wildlife Management Area
    set_key US-7042 KFF-5678  # R.D. Bailey Lake Wildlife Management Area
    set_key US-7044 KFF-5688  # Tug Fork Wildlife Management Area
    set_key US-7045 KFF-5652  # Amherst/Plymouth Wildlife Management Area
    set_key US-7046 KFF-5655  # Beech Fork Lake Wildlife Management Area
    set_key US-7047 KFF-5657  # Big Ugly Wildlife Management Area
    set_key US-7048 KFF-5662  # Chief Cornstalk Wildlife Management Area
    set_key US-7049 KFF-5664  # East Lynn Lake Wildlife Management Area
    set_key US-7052 KFF-5670  # Laurel Lake Wildlife Management Area
    set_key US-7053 KFF-5672  # McClintic Wildlife Management Area
    set_key US-7055 KFF-5674  # Morris Creek State Wildlife Management Area
    set_key US-7059 KFF-5666  # Frozen Camp Wildlife Management Area
    set_key US-7060 KFF-5668  # Hughes River Wildlife Management Area
    set_key US-7062 KFF-5679  # Ritchie Mines Wildlife Management Area
    set_key US-7066 KFF-5686  # The Jug Wildlife Management Area
    set_key US-7069 KFF-4985  # Panther State Forest
    set_key US-7070 KFF-7377  # O'Keefe Wildlife Management Area
    set_key US-7072 KFF-7379  # Riverfront Wildlife Management Area
    set_key US-7075 KFF-7376  # Muscadine Farms Wildlife Management Area
    set_key US-7077 KFF-7373  # Leroy Percy Wildlife Management Area
    set_key US-7078 KFF-7288  # Howard Miller Wildlife Management Area
    set_key US-7079 KFF-7382  # Twin Oaks Wildlife Management Area
    set_key US-7080 KFF-7380  # Sunflower Wildlife Management Area
    set_key US-7081 KFF-7290  # Lake George Wildlife Management Area
    set_key US-7083 KFF-7374  # Mahannah Wildlife Management Area
    set_key US-7092 KFF-7381  # Tuscumbia Wildlife Management Area
    set_key US-7093 KFF-7287  # Divide Section Wildlife Management Area
    set_key US-7095 KFF-7289  # John Bell Williams Wildlife Management Area
    set_key US-7103 KFF-7375  # Malmaison Wildlife Management Area
    set_key US-7117 KFF-7286  # Canemount Wildlife Management Area
    set_key US-7127 KFF-7378  # Okatibbee Lake State Recreation Area
    set_key US-7135 KFF-6050  # Blue Ridge Wildlife Management Area
    set_key US-7136 KFF-6083  # Tuckahoe Wildlife Management Area
    set_key US-7137 KFF-6062  # Cooper's Creek Wildlife Management Area
    set_key US-7138 KFF-6057  # Chestatee Wildlife Management Area
    set_key US-7141 KFF-6059  # Clybel Wildlife Management Area
    set_key US-7142 KFF-6077  # Redlands Wildlife Management Area
    set_key US-7144 KFF-5368  # La Salle Lake State Recreation Area
    set_key US-7145 KFF-5369  # Minnesota Valley State Recreation Area
    set_key US-7146 KFF-5370  # Red River State Recreation Area
    set_key US-7147 KFF-5475  # Centennial State Forest
    set_key US-7148 KFF-6828  # Lake Vermillion Soudan Iron Mine
    set_key US-7149 KFF-4551  # Petit Manan National Wildlife Refuge
    set_key US-7155 KFF-6738  # Upper Hillsborough Preserve State Conservation Area
    set_key US-7158 KFF-7245  # Benson Creek State Natural Area
    set_key US-7159 KFF-7246  # Big Creek State Natural Area
    set_key US-7164 KFF-7343  # Devil's Eyebrow State Natural Area
    set_key US-7165 KFF-7344  # Devil's Knob-Devil's Backbone State Natural Area
    set_key US-7167 KFF-7353  # Kings River Falls State Natural Area
    set_key US-7171 KFF-5464  # Warren Prairie State Natural Area
    set_key US-7172 KFF-7447  # White Cliffs State Natural Area
    set_key US-7173 KFF-7250  # Cherokee Prairie State Natural Area
    set_key US-7174 KFF-5454  # Falcon Bottoms State Natural Area
    set_key US-7175 KFF-7346  # Foushee Cave State Natural Area
    set_key US-7176 KFF-7349  # Garrett Hollow State Natural Area
    set_key US-7178 KFF-7352  # H. E. Flanagan Prairie State Natural Area
    set_key US-7179 KFF-7351  # Hall Creek State Natural Area
    set_key US-7180 KFF-5101  # Holland Bottoms State Natural Area
    set_key US-7183 KFF-7357  # Longview Saline State Natural Area
    set_key US-7184 KFF-5107  # Moro Big Pine State Natural Area
    set_key US-7185 KFF-7360  # Pine City State Natural Area
    set_key US-7186 KFF-5118  # Seven Devils Swamp State Natural Area
    set_key US-7187 KFF-7442  # Slippery Hollow State Natural Area
    set_key US-7188 KFF-7445  # Terre Noire State Natural Area
    set_key US-7256 KFF-4552  # Midewin National Grassland
    set_key US-7261 KFF-5080  # Bayou Des Arc Wildlife Management Area
    set_key US-7262 KFF-5081  # Beaver Lake Wildlife Management Area
    set_key US-7263 KFF-5452  # Bell Slough Wildlife Management Area
    set_key US-7264 KFF-5082  # Beryl Anthony Lower Ouachita Wildlife Management Area
    set_key US-7265 KFF-5083  # Big Lake Wildlife Management Area
    set_key US-7266 KFF-5085  # Blue Mountain Wildlife Management Area
    set_key US-7267 KFF-5093  # Dr Lester Stizes III Bois d'Arc Wildlife Management Area
    set_key US-7268 KFF-7247  # Brewer Lake/Cypress Creek Wildlife Management Area
    set_key US-7270 KFF-0646  # Buffalo National River Wildlife Management Area
    set_key US-7271 KFF-5086  # Camp Robinson Wildlife Management Area
    set_key US-7272 KFF-5087  # Caney Creek Wildlife Management Area
    set_key US-7273 KFF-7248  # Casey Jones Wildlife Management Area
    set_key US-7275 KFF-7249  # Cedar Mountain Wildlife Management Area
    set_key US-7276 KFF-5088  # Cherokee Wildlife Management Area
    set_key US-7277 KFF-7341  # Crossett Experimental Forest Wildlife Management Area
    set_key US-7278 KFF-5453  # Cypress Bayou Wildlife Management Area
    set_key US-7279 KFF-5119  # Sheffield Nelson Dagmar Wildlife Management Area
    set_key US-7280 KFF-5090  # Dardanelle Wildlife Management Area
    set_key US-7281 KFF-7342  # Dave Donaldson Black River Wildlife Management Area
    set_key US-7282 KFF-7168  # Departee Creek Wildlife Management Area
    set_key US-7283 KFF-5092  # DeQueen Lake Wildlife Management Area
    set_key US-7284 KFF-7345  # Earl Buss Bayou DeView Wildlife Management Area
    set_key US-7285 KFF-5094  # Ed Gordon Pt Remove Wildlife Management Area
    set_key US-7286 KFF-5095  # Fort Chaffee Wildlife Management Area
    set_key US-7287 KFF-7163  # Galla Creek Wildlife Management Area
    set_key US-7288 KFF-5097  # Gene Rush Wildlife Management Area
    set_key US-7289 KFF-7162  # Greers Ferry Wildlife Management Area
    set_key US-7290 KFF-5098  # Gum Flats Wildlife Management Area
    set_key US-7291 KFF-5099  # Harold E Alexander Spring River Wildlife Management Area
    set_key US-7292 KFF-5455  # Harris Brake Wildlife Management Area
    set_key US-7293 KFF-7161  # Hobbs State Park Wildlife Management Area
    set_key US-7294 KFF-7020  # Holland Bottoms Wildlife Management Area
    set_key US-7295 KFF-5456  # Hope Upland Wildlife Management Area
    set_key US-7296 KFF-5102  # Howard County Wildlife Management Area
    set_key US-7297 KFF-6950  # Jack Mountain Wildlife Management Area
    set_key US-7298 KFF-7166  # Jamestown Independence County Wildlife Management Area
    set_key US-7299 KFF-5103  # Jim Kress Wildlife Management Area
    set_key US-7300 KFF-5104  # Lafayette County Wildlife Management Area
    set_key US-7301 KFF-7355  # Lake Greeson Wildlife Management Area
    set_key US-7302 KFF-7167  # Lake Overcup Wildlife Management Area
    set_key US-7303 KFF-5458  # Maumelle River Wildlife Management Area
    set_key US-7304 KFF-5105  # McIlroy Madison County Wildlife Management Area
    set_key US-7305 KFF-5106  # Mike Freeze Wattensaw Wildlife Management Area
    set_key US-7306 KFF-5108  # Mount Magazine Wildlife Management Area
    set_key US-7307 KFF-5109  # Muddy Creek Wildlife Management Area
    set_key US-7308 KFF-7164  # Nacatosh Ravines Wildlife Management Area
    set_key US-7309 KFF-5459  # Nimrod Lloyd Millwood Wildlife Management Area
    set_key US-7310 KFF-5110  # Norfolk Lake Wildlife Management Area
    set_key US-7311 KFF-7359  # Ozan Wildlife Management Area
    set_key US-7313 KFF-7165  # Palmetto Flats Wildlife Management Area
    set_key US-7314 KFF-5112  # Petit Jean River Wildlife Management Area
    set_key US-7315 KFF-5113  # Piney Creeks Wildlife Management Area
    set_key US-7316 KFF-5114  # Poison Springs Wildlife Management Area
    set_key US-7317 KFF-5115  # Provo Wildlife Management Area
    set_key US-7318 KFF-7440  # Rainey Wildlife Management Area
    set_key US-7319 KFF-5116  # Rex Hancock Black Swamp Wildlife Management Area
    set_key US-7320 KFF-5460  # Rick Evans Grandview Prarie Wildlife Management Area
    set_key US-7323 KFF-7441  # Robert H Hankins Mud Creek Wildlife Management Area
    set_key US-7324 KFF-5117  # Scott Henderson Gulf Mountain Wildlife Management Area
    set_key US-7325 KFF-5120  # Shirey Bay Rainey Brake Wildlife Management Area
    set_key US-7326 KFF-5461  # Stateline Sand Ponds Wildlife Management Area
    set_key US-7327 KFF-7444  # Stone Prarie Wildlife Management Area
    set_key US-7328 KFF-5122  # Sulphur River Wildlife Management Area
    set_key US-7331 KFF-5463  # W E Brewer Scatter Creek Wildlife Management Area
    set_key US-7332 KFF-5125  # Wedington Wildlife Management Area
    set_key US-7333 KFF-5126  # White Rock Wildlife Management Area
    set_key US-7335 KFF-5127  # Winona Wildlife Management Area
    set_key US-7336 KFF-7244  # Bearcat Hollow Wildlife Management Area
    set_key US-7338 KFF-5089  # Cut-Off Creek Wildlife Management Area
    set_key US-7340 KFF-7348  # Frog Bayou Wildlife Management Area
    set_key US-7342 KFF-5100  # Henry Gray Hurricane Lake Wildlife Management Area
    set_key US-7345 KFF-7356  # Lee Creek Wildlife Management Area
    set_key US-7347 KFF-5457  # Loafer's Glory Wildlife Management Area
    set_key US-7349 KFF-5111  # Ozark Lake Wildlife Management Area
    set_key US-7350 KFF-7361  # Prairie Bayou Wildlife Management Area
    set_key US-7354 KFF-7443  # Spring Bank Wildlife Management Area
    set_key US-7355 KFF-5462  # Steve N Wilson Raft Creek Wildlife Management Area
    set_key US-7356 NIL-0000  # St Francis National Forest WMA; WWFF candidates: KFF-4648, KFF-6039
    set_key US-7357 KFF-5123  # Sylamore Wildlife Management Area
    set_key US-7358 KFF-5124  # Trusten Holder Wildlife Management Area
    set_key US-7359 KFF-7446  # Two Bayou Creek Wildlife Management Area
    set_key US-7360 KFF-4550  # Curlew National Grassland
    set_key US-7363 KFF-4960  # Morley Nelson Snake River Birds of Prey National Conservation Area
    set_key US-7365 KFF-6858  # St. Anthony Sand Dunes Wilderness Study Area
    set_key US-7369 KFF-6744  # Mountain Tea State Forest
    set_key US-7376 KFF-5078  # Burleigh H. Murray Ranch State Park
    set_key US-7377 KFF-4950  # Bolsa Chica Ecological Reserve
    set_key US-7378 KFF-4951  # Upper Newport Bay Ecological Reserve
    set_key US-7379 KFF-4956  # King Range National Conservation Area
    set_key US-7380 KFF-5129  # Cardiff State Beach
    set_key US-7381 KFF-4954  # Las Cienegas National Conservation Area
    set_key US-7382 KFF-7258  # Arlington State Wildlife Area
    set_key US-7389 KFF-6706  # Cypress Creek Preserve State Conservation Area
    set_key US-7440 KFF-5084  # Big Timber Wildlife Management Area
    set_key US-7446 KFF-6060  # Cohutta Wildlife Management Area
    set_key US-7447 KFF-6055  # Chattahoochee Wildlife Management Area
    set_key US-7448 KFF-6071  # Lula Bridge Wildlife Management Area
    set_key US-7449 KFF-6052  # Buck Shoals Wildlife Management Area
    set_key US-7450 KFF-6085  # Warwoman Wildlife Management Area
    set_key US-7451 KFF-6082  # Swallow Creek Wildlife Management Area
    set_key US-7452 KFF-6078  # Rich Mountain Wildlife Management Area
    set_key US-7453 KFF-6046  # Allatoona Wildlife Management Area
    set_key US-7454 KFF-6072  # McGraw Ford Wildlife Management Area
    set_key US-7455 KFF-6069  # Lake Russell Wildlife Management Area
    set_key US-7474 KFF-4627  # Carpinteria State Beach
    set_key US-7475 KFF-6731  # Starkey Wilderness/Serenova Preserve State Conservation Area
    set_key US-7476 KFF-4528  # Butte Valley National Grassland
    set_key US-7477 KFF-4562  # Cimarron National Grassland
    set_key US-7478 KFF-4574  # Oglala National Grassland
    set_key US-7479 KFF-4563  # Kiowa National Grassland
    set_key US-7480 KFF-4575  # Black Kettle National Grassland
    set_key US-7481 NIL-0000  # Rita Blanca National Grassland (OK); WWFF candidates: KFF-4582, KFF-4583
    set_key US-7482 KFF-4576  # Crooked River National Grassland
    set_key US-7483 KFF-4581  # McClellan Creek National Grassland
    set_key US-7484 KFF-4566  # Cedar River National Grassland
    set_key US-7485 KFF-4569  # Little Missouri National Grassland
    set_key US-7486 KFF-4573  # Sheyenne National Grassland
    set_key US-7487 KFF-4578  # Buffalo Gap National Grassland
    set_key US-7488 KFF-4579  # Fort Pierre National Grassland
    set_key US-7489 KFF-4580  # Grand River National Grassland
    set_key US-7490 KFF-4548  # Pawnee National Grassland
    set_key US-7491 KFF-4547  # Comanche National Grassland
    set_key US-7494 KFF-4962  # Red Rock Canyon National Conservation Area
    set_key US-7495 KFF-6990  # Mason Valley Wildlife Management Area
    set_key US-7496 KFF-5774  # Fox Valley Lake State Conservation Area
    set_key US-7497 KFF-5775  # Frost Island State Conservation Area
    set_key US-7498 KFF-5773  # Danville State Conservation Area
    set_key US-7502 KFF-6307  # A. Busch Jr at Four Rivers Wetland Reserve
    set_key US-7503 KFF-6324  # Bushwacker Lake State Conservation Area
    set_key US-7504 KFF-5298  # Assunpink Wildlife Management Area
    set_key US-7505 KFF-5295  # Round Valley State Recreation Area
    set_key US-7507 KFF-5296  # Warren Grove State Recreation Area
    set_key US-7508 KFF-6845  # Pulaski State Park
    set_key US-7512 KFF-6308  # Baltimore Bend State Conservation Area
    set_key US-7513 KFF-6312  # Bismarck State Conservation Area
    set_key US-7514 KFF-6375  # Marshall Junction State Conservation Area
    set_key US-7515 KFF-6679  # Schifferdecker Memorial State Conservation Area
    set_key US-7516 KFF-6693  # White Memorial State Conservation Area
    set_key US-7517 KFF-6403  # Settle's Ford State Conservation Area
    set_key US-7521 KFF-6315  # Bluffwoods State Conservation Area
    set_key US-7523 KFF-5091  # DeGray Wildlife Management Area
    set_key US-7527 KFF-5197  # Sunset Rock State Park
    set_key US-7530 KFF-5333  # Centennial Watershed State Forest
    set_key US-7531 KFF-5334  # Cockaponset State Forest
    set_key US-7534 KFF-5342  # Mohegan State Forest
    set_key US-7536 KFF-5343  # Nassahegon State Forest
    set_key US-7537 KFF-5344  # Natchaug State Forest
    set_key US-7538 KFF-5346  # Naugatuck State Forest
    set_key US-7539 KFF-6820  # Platt Hill
    set_key US-7541 KFF-5357  # Salmon River State Forest
    set_key US-7545 KFF-6825  # Wooster Mountain
    set_key US-7546 KFF-5360  # Wyantenock State Forest
    set_key US-7548 NIL-0000  # Paugnut State Forest; WWFF candidates: KFF-5351, KFF-5352
    set_key US-7568 KFF-7325  # Barkley State Natural Area
    set_key US-7569 KFF-7326  # Beason Creek Wildlife Management Area
    set_key US-7572 KFF-7327  # Big Sandy Wildlife Management Area
    set_key US-7573 KFF-7328  # Black Bayou Refuge Wildlife Management Area
    set_key US-7574 KFF-7329  # Blackburn Fork Wildlife Management Area
    set_key US-7579 KFF-7330  # Colonel Forrest V Durand Wildlife Management Area
    set_key US-7582 KFF-7331  # Cove Creek Wildlife Management Area
    set_key US-7586 KFF-6410  # Toronto Springs State Conservation Area
    set_key US-7588 KFF-7333  # Foothills Wildlife Management Area
    set_key US-7589 KFF-7334  # Fort Ridge Wildlife Management Area
    set_key US-7592 KFF-7420  # Happy Hollow Wildlife Management Area
    set_key US-7596 KFF-7421  # Headwaters Wildlife Management Area
    set_key US-7598 KFF-7422  # Hiwassee Refuge Wildlife Management Area
    set_key US-7599 KFF-7424  # Keyes Harrison Wildlife Management Area
    set_key US-7600 KFF-7425  # Kyles Ford Wildlife Management Area
    set_key US-7608 KFF-7430  # Normandy Wildlife Management Area
    set_key US-7609 KFF-7431  # North Cumberland Wildlife Management Area
    set_key US-7610 KFF-7433  # Old Hickory Wildlife Management Area
    set_key US-7611 KFF-7434  # Owl Hollow Mill Wildlife Management Area
    set_key US-7612 KFF-7435  # Paint Rock Refuge Wildlife Management Area
    set_key US-7614 KFF-6908  # Pea Ridge Wildlife Management Area
    set_key US-7615 KFF-7436  # Percy Priest Wildlife Management Area
    set_key US-7619 KFF-7455  # Shelton Ferry Wildlife Management Area
    set_key US-7622 KFF-7459  # Tellico Lake Wildlife Management Area
    set_key US-7623 KFF-7460  # Thorny Cypress Wildlife Management Area
    set_key US-7625 KFF-7461  # Tigrett Wildlife Management Area
    set_key US-7627 KFF-7464  # West Sandy Wildlife Management Area
    set_key US-7628 KFF-7465  # Yuchi Refuge Wildlife Management Area
    set_key US-7636 KFF-6850  # Widewater State Park
    set_key US-7638 KFF-6578  # Goose Lake Prairie State Natural Area
    set_key US-7645 KFF-5628  # Assowoman Bay State Wildlife Area
    set_key US-7646 KFF-5617  # Augustine State Wildlife Area
    set_key US-7647 KFF-5620  # Blackiston State Wildlife Area
    set_key US-7648 KFF-5616  # Chesapeake and Delaware Canal Conservation Area
    set_key US-7649 KFF-5618  # Cedar Swamp State Wildlife Area
    set_key US-7650 KFF-6289  # Eagles Nest State Wildlife Area
    set_key US-7653 KFF-5619  # Toni Florio Woodland Beach State Wildlife Area
    set_key US-7654 KFF-6352  # Hazel Hill Lake Conservation Reserve
    set_key US-7655 KFF-6422  # J.N. Turkey Kearn Memorial Wildlife Area
    set_key US-7659 KFF-6354  # Huckleberry Ridge Conservation Reserve
    set_key US-7660 KFF-6342  # Fort Crowder Conservation Reserve
    set_key US-7661 KFF-6334  # Douglas Branch Conservation Reserve
    set_key US-7663 KFF-5704  # Edward Anderson Conservation Reserve
    set_key US-7664 KFF-5705  # Dupont Reservation Conservation Reserve
    set_key US-7665 KFF-5706  # Ted Shanks Conservation Reserve
    set_key US-7668 KFF-6299  # Little Lost Creek Conservation Reserve
    set_key US-7669 KFF-6341  # Flag Spring Conservation Reserve
    set_key US-7679 KFF-6379  # Moniteau Creek Conservation Reserve
    set_key US-7680 KFF-5781  # Upper Mississippi Conservation Reserve
    set_key US-7681 KFF-5783  # William R Logan Conservation Reserve
    set_key US-7687 KFF-5563  # Drummond Flats Wildlife Management Area
    set_key US-7697 KFF-7221  # Lewis and Clark Wildlife Management Area
    set_key US-7698 KFF-7223  # Trenton Wildlife Management Area
    set_key US-7702 KFF-7220  # Lonetree WMA
    set_key US-7713 KFF-5079  # Loblolly Marsh State Nature Preserve
    set_key US-7724 KFF-6579  # Avondale Wildlife Management Area
    set_key US-7725 KFF-5866  # Browns Branch Wildlife Management Area
    set_key US-7726 KFF-6586  # Earleville Wildlife Management Area
    set_key US-7727 KFF-6496  # Grove Farm Wildlife Management Area
    set_key US-7728 KFF-6588  # Gwynnbrook Wildlife Management Area
    set_key US-7729 KFF-6590  # Hugg-Thomas Wildlife Management Area
    set_key US-7730 KFF-5870  # McKee-Breshers Wildlife Management Area
    set_key US-7731 KFF-5525  # Millington Wildlife Management Area
    set_key US-7732 KFF-5875  # Old Bohemia Wildlife Management Area
    set_key US-7733 KFF-6598  # Strider Wildlife Management Area
    set_key US-7735 KFF-5529  # Cedar Island Wildlife Management Area
    set_key US-7736 KFF-4840  # Deal Island Wildlife Management Area
    set_key US-7737 KFF-5531  # E.A. Vaughn Wildlife Management Area
    set_key US-7738 KFF-5528  # Ellis Bay Wildlife Management Area
    set_key US-7739 KFF-4841  # Fairmount Wildlife Management Area
    set_key US-7740 KFF-4838  # Fishing Bay Wildlife Management Area
    set_key US-7741 KFF-5526  # Idylwild Wildlife Management Area
    set_key US-7742 KFF-6591  # Isle of Wight Wildlife Management Area
    set_key US-7743 KFF-6592  # Johnson Wildlife Management Area
    set_key US-7744 KFF-6593  # LeCompte Wildlife Management Area
    set_key US-7745 KFF-6594  # Linkwood Wildlife Management Area
    set_key US-7746 KFF-5869  # Maryland Marine Properties Wildlife Management Area
    set_key US-7748 KFF-5532  # Nanticoke River Wildlife Management Area
    set_key US-7749 KFF-6500  # Pocomoke Sound Wildlife Management Area
    set_key US-7750 KFF-5530  # South Marsh Island Wildlife Management Area
    set_key US-7751 KFF-6599  # Tar Bay Wildlife Management Area
    set_key US-7752 KFF-5876  # Taylors Island Wildlife Management Area
    set_key US-7753 KFF-6600  # Wellington Wildlife Management Area
    set_key US-7754 KFF-6581  # Bowen Wildlife Management Area
    set_key US-7755 KFF-5867  # Cedar Point Wildlife Management Area
    set_key US-7756 KFF-6582  # Cheltenham Wildlife Management Area
    set_key US-7757 KFF-6583  # Chicamuxen Wildlife Management Area
    set_key US-7758 KFF-5524  # Myrtle Grove Wildlife Management Area
    set_key US-7760 KFF-5874  # Nanjemoy Creek Wildlife Management Area
    set_key US-7761 KFF-6498  # Parker's Creek Wildlife Management Area
    set_key US-7762 KFF-6501  # Popes Creek Wildlife Management Area
    set_key US-7763 KFF-6502  # Riverside Wildlife Management Area
    set_key US-7764 KFF-6580  # Belle Grove Wildlife Management Area
    set_key US-7765 KFF-6495  # Billmeyer Wildlife Management Area
    set_key US-7766 KFF-6584  # Cunningham Swamp Wildlife Management Area
    set_key US-7767 KFF-4839  # Dans Mountain Wildlife Management Area
    set_key US-7768 KFF-5868  # Frederick City Watershed Cooperative Wildlife Management Area
    set_key US-7769 KFF-6589  # Heaters Island Wildlife Management Area
    set_key US-7770 KFF-4842  # Indian Springs Wildlife Management Area
    set_key US-7771 KFF-5872  # Mt. Nebo Wildlife Management Area
    set_key US-7772 KFF-6595  # Prathers Neck Wildlife Management Area
    set_key US-7773 KFF-6596  # Ridenour Swamp Wildlife Management Area
    set_key US-7774 KFF-5527  # Sideling Hill Wildlife Management Area
    set_key US-7775 KFF-4843  # Warrior Mountain Wildlife Management Area
    set_key US-7777 KFF-6585  # Dierssen Wildlife Management Area
    set_key US-7778 KFF-6497  # Islands of the Potomac Wildlife Management Area
    set_key US-7779 KFF-6499  # Pocomoke River Wildlife Management Area
    set_key US-7780 KFF-6597  # Sinepuxent Bay Wildlife Management Area
    set_key US-7781 KFF-6601  # Wetipquin Wildlife Management Area
    set_key US-7783 KFF-6587  # Gravel Hill Swamp Wildlife Management Area
    set_key US-7804 KFF-6494  # Great Falls Park
    set_key US-7837 KFF-6407  # Taberville Prairie State Conservation Area
    set_key US-7838 KFF-6066  # Gaither Wildlife Management Area
    set_key US-7840 KFF-6338  # Elam Bend State Conservation Area
    set_key US-7844 KFF-4657  # Adams Homestead State Nature Preserve
    set_key US-7845 KFF-6818  # Fisher's Peak
    set_key US-7846 KFF-6345  # Gallatin State Conservation Area
    set_key US-7849 KFF-6483  # Spring Valley State Wildlife Area
    set_key US-7850 KFF-6456  # Caesar Creek Lake State Wildlife Area
    set_key US-7851 KFF-6372  # Marais Temps Clair State Conservation Area
    set_key US-7852 KFF-6079  # Richmond Hill Wildlife Management Area
    set_key US-7857 KFF-5937  # Grand River State Game Land
    set_key US-7858 KFF-5631  # Dames Ferry Campground State Park
    set_key US-7863 KFF-6663  # Little Bean Marsh State Conservation Area
    set_key US-7867 KFF-5419  # Benedictine Bottoms State Wildlife Area
    set_key US-7873 KFF-6628  # Agency State Conservation Area
    set_key US-7874 KFF-6630  # Arthur Dupree Memorial State Conservation Area
    set_key US-7875 KFF-6305  # Aspinwall Bend State Conservation Area
    set_key US-7877 KFF-5632  # Valley of Fires National Recreation Area
    set_key US-7879 KFF-5796  # Citrus Wildlife Management Area
    set_key US-7880 KFF-7428  # Luper Mountain Wildlife Management Area
    set_key US-7881 KFF-6045  # Alapaha River Wildlife Management Area
    set_key US-7882 KFF-6063  # Doerun Pitcherplant Bog Wildlife Management Area
    set_key US-7883 KFF-6086  # Westpoint Wildlife Management Area
    set_key US-7884 KFF-6569  # Kenai Mountains-Turnagain Arm National Heritage Area
    set_key US-7886 KFF-5633  # Yukon-Charley Rivers National Preserve
    set_key US-7887 KFF-5634  # Parashant National Monument
    set_key US-7894 KFF-6076  # Pine Log Wildlife Management Area
    set_key US-7895 KFF-6081  # Sheffield Wildlife Management Area
    set_key US-7897 KFF-6047  # Arrowhead Wildlife Management Area
    set_key US-7898 KFF-6061  # Conasauga River Wildlife Management Area
    set_key US-7899 KFF-6054  # Carter's Lake Wildlife Management Area
    set_key US-7900 KFF-6064  # Echeconnee Creek Wildlife Management Area
    set_key US-7901 KFF-6074  # Ohoopee Dunes Wildlife Management Area
    set_key US-7902 KFF-6084  # Walton Wildlife Management Area
    set_key US-7903 KFF-6087  # Zahnd Wildlife Management Area
    set_key US-7904 KFF-6051  # Broad River Wildlife Management Area
    set_key US-7905 KFF-6053  # Canoochee Sandhills Wildlife Management Area
    set_key US-7906 KFF-6056  # Chattahoochee Fall Line Wildlife Management Area
    set_key US-7907 KFF-6058  # Clarks Hill Wildlife Management Area
    set_key US-7908 KFF-6065  # Fishing Creek Wildlife Management Area
    set_key US-7909 KFF-6067  # Germany Creek Wildlife Management Area
    set_key US-7910 KFF-6068  # Keg Creek Wildlife Management Area
    set_key US-7911 KFF-6070  # Lake Walter F. George Wildlife Management Area
    set_key US-7912 KFF-6073  # Montezuma Bluffs Wildlife Management Area
    set_key US-7913 KFF-6075  # Otting Wildlife Management Area
    set_key US-7914 KFF-6080  # Sandhills East Wildlife Management Area
    set_key US-7918 KFF-5420  # Byron Walker State Wildlife Area
    set_key US-7919 KFF-5421  # Cedar Bluff State Wildlife Area
    set_key US-7920 KFF-5422  # Cheney State Wildlife Area
    set_key US-7921 KFF-5423  # Cheyenne Bottoms State Wildlife Area
    set_key US-7922 KFF-5424  # Clinton State Wildlife Area
    set_key US-7923 KFF-5425  # Copan State Wildlife Area
    set_key US-7924 KFF-5426  # Council Grove State Wildlife Area
    set_key US-7925 KFF-5427  # El Dorado State Wildlife Area
    set_key US-7926 KFF-5428  # Elk City Reservoir State Wildlife Area
    set_key US-7927 KFF-5429  # Fall River State Wildlife Area
    set_key US-7928 KFF-5430  # Glen Elder State Wildlife Area
    set_key US-7929 KFF-5431  # Hillsdale State Wildlife Area
    set_key US-7930 KFF-5432  # Hollister State Wildlife Area
    set_key US-7931 KFF-5433  # Jamestown State Wildlife Area
    set_key US-7932 KFF-5434  # Kansas Veterans State Wildlife Area
    set_key US-7933 KFF-5435  # Kaw State Wildlife Area
    set_key US-7934 KFF-5436  # Lovewell State Wildlife Area
    set_key US-7935 KFF-5437  # Marais des Cygnes State Wildlife Area
    set_key US-7936 KFF-5438  # Marion State Wildlife Area
    set_key US-7937 KFF-5439  # McPherson Valley Wetlands State Wildlife Area
    set_key US-7938 KFF-5440  # Milford State Wildlife Area
    set_key US-7939 KFF-5441  # Mined Land State Wildlife Area
    set_key US-7940 KFF-5442  # Norton State Wildlife Area
    set_key US-7941 KFF-5443  # Perry State Wildlife Area
    set_key US-7942 KFF-5444  # Pratt Sandhills State Wildlife Area
    set_key US-7943 KFF-5445  # Sandsage Bison Range State Wildlife Area
    set_key US-7944 KFF-5446  # Smoky Hill State Wildlife Area
    set_key US-7945 KFF-5447  # Toronto State Wildlife Area
    set_key US-7946 KFF-5448  # Tuttle Creek State Wildlife Area
    set_key US-7947 KFF-5449  # Webster State Wildlife Area
    set_key US-7948 KFF-5450  # Wilson State Wildlife Area
    set_key US-7949 KFF-5451  # Woodson State Wildlife Area
    set_key US-7950 KFF-4708  # Camp Nelson National Monument
    set_key US-7951 KFF-6864  # Green River State Forest
    set_key US-7952 KFF-7371  # Marrowbone State Forest
    set_key US-7957 KFF-6882  # Hall-Hill/Vernon-Douglas State Nature Preserve
    set_key US-7958 KFF-6885  # Kentucky River Palisades/Tom Dorman Nature Preserve
    set_key US-7960 KFF-7271  # Crooked Creek State Nature Preserve
    set_key US-7961 KFF-6884  # Jesse Stuart State Nature Preserve
    set_key US-7962 KFF-6870  # Little South Fork State Natural Area
    set_key US-7963 KFF-6886  # Pilot Knob State Nature Preserve
    set_key US-7964 KFF-6873  # William H. Martin State Nature Preserve
    set_key US-7965 KFF-6878  # Brigadoon State Nature Preserve
    set_key US-7966 KFF-6875  # Bad Branch State Nature Preserve
    set_key US-7967 KFF-6876  # Blanton Forest State Nature Preserve
    set_key US-7968 KFF-6879  # E. Lucy Braun State Nature Preserve
    set_key US-7969 KFF-6871  # Martin's Fork State Natural Area
    set_key US-7970 KFF-6872  # Sinking Creek State Natural Area
    set_key US-7996 KFF-4553  # Black Coulee National Wildlife Refuge
    set_key US-7997 KFF-4554  # Creedman Coulee National Wildlife Refuge
    set_key US-7998 KFF-4557  # Hailstone National Wildlife Refuge
    set_key US-7999 KFF-4555  # Hewitt Lake National Wildlife Refuge
    set_key US-8000 KFF-4556  # Lake Thibadeau National Wildlife Refuge
    set_key US-8002 KFF-4558  # Ninepipe National Wildlife Refuge
    set_key US-8003 KFF-4559  # Pablo National Wildlife Refuge
    set_key US-8004 KFF-4560  # Swan River National Wildlife Refuge
    set_key US-8006 KFF-5644  # Rachel Carson State Reserve
    set_key US-8014 NIL-0000  # Nashua, Squannacook, Nissitissit (NH) National Scenic River; WWFF candidates: KFF-7282, KFF-7309
    set_key US-8015 KFF-6943  # Wildcat National Wild and Scenic River
    set_key US-8030 KFF-5297  # Absecon Wildlife Management Area
    set_key US-8031 KFF-5299  # Bear Swamp Wildlife Management Area
    set_key US-8032 KFF-5300  # Black River Wildlife Management Area
    set_key US-8033 KFF-5301  # Buckshutem Wildlife Management Area
    set_key US-8034 KFF-5302  # Cape May Coastal Wetlands Wildlife Management Area
    set_key US-8035 KFF-5303  # Colliers Mill Wildlife Management Area
    set_key US-8036 KFF-5304  # Dennis Creek Wildlife Management Area
    set_key US-8037 KFF-5305  # Dix Wildlife Management Area
    set_key US-8038 KFF-5306  # Egg Island Wildlife Management Area
    set_key US-8039 KFF-5307  # Forked River Mt Wildlife Management Area
    set_key US-8040 KFF-5308  # Greenwood Forest Wildlife Management Area
    set_key US-8041 KFF-5309  # Hammonton Creek Wildlife Management Area
    set_key US-8042 KFF-5310  # Heislerville Wildlife Management Area
    set_key US-8043 KFF-5312  # Makepeace Lake Wildlife Management Area
    set_key US-8044 KFF-5313  # Manchester Wildlife Management Area
    set_key US-8045 KFF-5314  # Millville Wildlife Management Area
    set_key US-8046 KFF-5315  # New Sweden Wildlife Management Area
    set_key US-8047 KFF-5316  # Paulinskill Wildlife Management Area
    set_key US-8048 KFF-5317  # Pequest Wildlife Management Area
    set_key US-8049 KFF-5318  # Rockaway River Wildlife Management Area
    set_key US-8050 KFF-5319  # Salem River Wildlife Management Area
    set_key US-8051 KFF-5320  # Sparta Mountain Wildlife Management Area
    set_key US-8052 KFF-5321  # Stafford Forge Wildlife Management Area
    set_key US-8053 KFF-5322  # Swan Bay Wildlife Management Area
    set_key US-8054 KFF-5323  # Thundergut Pond Wildlife Management Area
    set_key US-8055 KFF-5324  # Tuckahoe Wildlife Management Area
    set_key US-8056 KFF-5325  # Turkey Swamp Wildlife Management Area
    set_key US-8057 KFF-5326  # Union Lake Wildlife Management Area
    set_key US-8058 KFF-5327  # White Oak Branch Wildlife Management Area
    set_key US-8059 KFF-5328  # Wildcat Ridge Wildlife Management Area
    set_key US-8060 KFF-5329  # Winslow Wildlife Management Area
    set_key US-8068 KFF-6838  # Shirley Chisolm State Park
    set_key US-8069 KFF-6836  # Genesee Valley Greenway State Park
    set_key US-8070 KFF-6835  # Catskill State Park
    set_key US-8072 KFF-4751  # Bristol Beach State Park
    set_key US-8073 KFF-7405  # Bluestone Wild State Forest
    set_key US-8077 KFF-5959  # Braddock Bay Wildlife Management Area
    set_key US-8078 KFF-5995  # Three Rivers Wildlife Management Area
    set_key US-8079 KFF-5997  # Tivoli Bays Wildlife Management Area
    set_key US-8081 KFF-0680  # Floyd Bennett Field National Historic District
    set_key US-8082 KFF-0680  # Jamaica Bay State Wildlife Area
    set_key US-8083 KFF-0680  # Canarsie Pier State Recreation Area
    set_key US-8084 KFF-0680  # Breezy Point Tip State Recreation Area
    set_key US-8085 KFF-0680  # Fort Tilden National Historic Site
    set_key US-8086 KFF-0680  # Jacob Riis Park National Historic Site
    set_key US-8087 KFF-0680  # Fort Wadsworth National Historic Site
    set_key US-8088 KFF-0680  # Miller Field State Recreation Area
    set_key US-8089 KFF-0680  # Great Kills Park State Recreation Area
    set_key US-8090 KFF-0680  # Frank Charles Park State Recreation Area
    set_key US-8093 KFF-7482  # David A. Sarnoff Pine Barrens State Forest
    set_key US-8098 KFF-5954  # Empire State State Trail
    set_key US-8099 KFF-5986  # Oak Orchard Wildlife Management Area
    set_key US-8100 KFF-7395  # Tonawanda Wildlife Management Area
    set_key US-8102 KFF-5962  # Catharine Creek Wildlife Management Area
    set_key US-8104 KFF-5635  # Willow Grove State Forest
    set_key US-8105 KFF-5636  # West Blue Rock State Forest
    set_key US-8107 KFF-6473  # Lake La Su An State Wildlife Area
    set_key US-8108 KFF-5952  # Killdeer Plains State Wildlife Area
    set_key US-8109 KFF-5950  # Big Island State Wildlife Area
    set_key US-8110 KFF-6491  # Woodbury State Wildlife Area
    set_key US-8111 KFF-6485  # Tri-Valley State Wildlife Area
    set_key US-8112 KFF-6766  # Appalachian Hills State Wildlife Area
    set_key US-8113 KFF-6465  # Egypt Valley State Wildlife Area
    set_key US-8114 KFF-6464  # East Fork State Wildlife Area
    set_key US-8117 KFF-5561  # Cimarron Bluff Wildlife Management Area
    set_key US-8118 KFF-5562  # Cimarron Hills Wildlife Management Area
    set_key US-8121 KFF-5565  # Fobb Bottom Wildlife Management Area
    set_key US-8122 KFF-5567  # Fort Supply Wildlife Management Area
    set_key US-8124 KFF-5568  # Heyburn Wildlife Management Area
    set_key US-8125 KFF-5570  # Hulah Wildlife Management Area
    set_key US-8127 KFF-7228  # John Dahl Wildlife Management Area
    set_key US-8130 KFF-7314  # Neosho Wildlife Management Area
    set_key US-8133 KFF-7315  # Sans Bois Wildlife Management Area
    set_key US-8135 KFF-5571  # Optima Wildlife Management Area
    set_key US-8136 KFF-5572  # Stringtown Wildlife Management Area
    set_key US-8137 KFF-5559  # Arbuckle Springs Wildlife Management Area
    set_key US-8138 KFF-5574  # Yourman Wildlife Management Area
    set_key US-8139 KFF-7316  # Grassy Slough Wildlife Management Area
    set_key US-8140 KFF-7119  # Gary Sherrer Wildlife Management Area
    set_key US-8145 KFF-5605  # McCalla Wildlife Management Area
    set_key US-8149 KFF-5607  # Oak Lea Wildlife Management Area
    set_key US-8151 KFF-5615  # Woodbury Wildlife Management Area
    set_key US-8155 KFF-4658  # Angostura State Recreation Area
    set_key US-8156 KFF-4659  # Beaver Creek State Natural Area
    set_key US-8157 KFF-4660  # Big Sioux State Recreation Area
    set_key US-8158 KFF-4661  # Big Stone Island State Recreation Area
    set_key US-8159 KFF-4662  # Burke Lake State Recreation Area
    set_key US-8160 KFF-4663  # Buryanek State Recreation Area
    set_key US-8161 KFF-4664  # Chief White Crane State Recreation Area
    set_key US-8162 KFF-4665  # Cow Creek State Recreation Area
    set_key US-8163 KFF-4666  # Farm Island State Recreation Area
    set_key US-8164 KFF-4707  # George S. Mickelson State Trail
    set_key US-8165 KFF-4668  # Indian Creek State Recreation Area
    set_key US-8166 KFF-4669  # LaFramboise Island State Natural Area
    set_key US-8167 KFF-4670  # Lake Alvin State Recreation Area
    set_key US-8168 KFF-4671  # Lake Cochrane State Recreation Area
    set_key US-8169 KFF-4672  # Lake Hiddenwood State Recreation Area
    set_key US-8170 KFF-4673  # Lake Louise State Recreation Area
    set_key US-8171 KFF-4674  # Lake Poinsett State Recreation Area
    set_key US-8172 KFF-4675  # Lake Thompson State Recreation Area
    set_key US-8173 KFF-4676  # Lake Vermillion State Recreation Area
    set_key US-8174 KFF-4677  # Lewis and Clark State Recreation Area
    set_key US-8175 KFF-4678  # Little Moreau State Recreation Area
    set_key US-8176 KFF-4679  # Llewellyn Johns State Recreation Area
    set_key US-8177 KFF-4680  # Mina Lake State Recreation Area
    set_key US-8178 KFF-4681  # North Point State Recreation Area
    set_key US-8179 KFF-4682  # North Wheeler State Recreation Area
    set_key US-8180 KFF-4683  # Oahe Downstream State Recreation Area
    set_key US-8181 KFF-4684  # Okobojo Point State Recreation Area
    set_key US-8182 KFF-4685  # Pease Creek State Recreation Area
    set_key US-8183 KFF-4686  # Pelican Lake State Recreation Area
    set_key US-8184 KFF-4687  # Pickerel Lake State Recreation Area
    set_key US-8185 KFF-4688  # Pierson Ranch State Recreation Area
    set_key US-8186 KFF-4689  # Platte Creek State Recreation Area
    set_key US-8187 KFF-4690  # Randall Creek State Recreation Area
    set_key US-8188 KFF-4691  # Revheim Bay State Recreation Area
    set_key US-8189 KFF-4692  # Richmond Lake State Recreation Area
    set_key US-8190 KFF-4693  # Rocky Point State Recreation Area
    set_key US-8191 KFF-4695  # Sandy Shore State Recreation Area
    set_key US-8192 KFF-4696  # Shadehill State Recreation Area
    set_key US-8193 KFF-4697  # Sheps Canyon State Recreation Area
    set_key US-8194 KFF-4698  # Snake Creek State Recreation Area
    set_key US-8195 NIL-0000  # Spearfish Canyon Nature Recreation Area
    set_key US-8196 KFF-4700  # Spring Creek State Recreation Area
    set_key US-8197 KFF-4701  # Springfield State Recreation Area
    set_key US-8198 KFF-4702  # Swan Creek State Recreation Area
    set_key US-8199 KFF-4703  # Walker's Point State Recreation Area
    set_key US-8200 KFF-4704  # West Bend State Recreation Area
    set_key US-8201 KFF-4705  # West Pollock State Recreation Area
    set_key US-8202 KFF-4706  # West Whitlock State Recreation Area
    set_key US-8228 KFF-4965  # Fort Stanton Snowy River National Conservation Area
    set_key US-8229 KFF-6319  # Brickyard Hill State Conservation Area
    set_key US-8230 KFF-6330  # Corning State Conservation Area
    set_key US-8231 KFF-6647  # Deroin Bend State Conservation Area
    set_key US-8232 KFF-6368  # Lower Hamburg Bend State Conservation Area
    set_key US-8233 KFF-6400  # Rush Bottoms State Conservation Area
    set_key US-8234 KFF-6685  # Star School Hill Prairie State Conservation Area
    set_key US-8235 KFF-6414  # Wolf Creek Bend State Conservation Area
    set_key US-8236 KFF-5770  # B.K. Leach Memorial State Conservation Area
    set_key US-8237 KFF-6631  # Bee Creek State Conservation Area
    set_key US-8238 KFF-6633  # Bethel Prairie State Conservation Area
    set_key US-8239 KFF-6313  # Black Island State Conservation Area
    set_key US-8240 KFF-6318  # Bonanza State Conservation Area
    set_key US-8241 KFF-6638  # Bristow State Conservation Area
    set_key US-8242 KFF-6320  # Buffalo Wallow State Conservation Area
    set_key US-8243 KFF-6322  # Bunch Hollow State Conservation Area
    set_key US-8244 KFF-6325  # Caney State Conservation Area
    set_key US-8245 KFF-6644  # Clear Creek State Conservation Area
    set_key US-8246 KFF-5772  # Cuivre Island State Conservation Area
    set_key US-8247 KFF-6648  # Dorris Creek Prairie State Conservation Area
    set_key US-8248 KFF-6344  # Fourche Creek State Conservation Area
    set_key US-8249 KFF-6347  # Girvin State Conservation Area
    set_key US-8250 KFF-6656  # Grand Trace State Conservation Area
    set_key US-8251 KFF-6658  # Honey Creek State Conservation Area
    set_key US-8252 KFF-6359  # Ketcherside Mountain State Conservation Area
    set_key US-8253 KFF-6364  # Little Compton Lake State Conservation Area
    set_key US-8254 KFF-6335  # Mincy State Conservation Area
    set_key US-8255 KFF-6665  # Mo-No-I Prairie State Conservation Area
    set_key US-8256 KFF-6380  # Monkey Mountain State Conservation Area
    set_key US-8257 KFF-6384  # Osage Prairie State Conservation Area
    set_key US-8258 KFF-6670  # Pa Sole Prairie State Conservation Area
    set_key US-8259 KFF-6389  # Pelican Island State Conservation Area
    set_key US-8260 KFF-5703  # Ranacker State Conservation Area
    set_key US-8261 KFF-6673  # Redwing Prairie State Conservation Area
    set_key US-8262 KFF-6396  # Riverbreaks State Conservation Area
    set_key US-8263 KFF-6688  # Treaty Line State Conservation Area
    set_key US-8264 KFF-6413  # White Ranch State Conservation Area
    set_key US-8265 KFF-6415  # Worthwine Island State Conservation Area
    set_key US-8266 KFF-6416  # Yellow Creek State Conservation Area
    set_key US-8268 KFF-6382  # Nishnabotna State Conservation Area
    set_key US-8269 KFF-6468  # Funk Bottoms State Wildlife Area
    set_key US-8270 KFF-6471  # Killbuck Marsh State Wildlife Area
    set_key US-8271 KFF-6487  # Willard Marsh State Wildlife Area
    set_key US-8273 KFF-5637  # Angel Peak Scenic National Recreation Area
    set_key US-8274 KFF-6675  # Risch State Conservation Area
    set_key US-8275 KFF-6406  # Stoney Point Prairie State Conservation Area
    set_key US-8276 KFF-6682  # Sky Prairie State Conservation Area
    set_key US-8277 KFF-6636  # Bluff Springs State Conservation Area
    set_key US-8278 KFF-6639  # Brush Creek State Conservation Area
    set_key US-8279 KFF-6373  # Marion Bottoms State Conservation Area
    set_key US-8280 KFF-6408  # Three Creeks State Conservation Area
    set_key US-8281 KFF-6321  # Buford Mountain State Conservation Area
    set_key US-8282 KFF-6411  # University Forest State Conservation Area
    set_key US-8284 KFF-6634  # Birdsong State Conservation Area
    set_key US-8285 KFF-6366  # Little River State Conservation Area
    set_key US-8286 KFF-6353  # Hornersville State Conservation Area
    set_key US-8290 KFF-7284  # Frye Mountain Wildlife Management Area
    set_key US-8295 NIL-0000  # Great Sand Dunes National Preserve
    set_key US-8296 NIL-0000  # Karval Reservoir State Wildlife Area
    set_key US-8297 KFF-6922  # Muggins Mountain Wilderness Area
    set_key US-8298 KFF-6921  # Mittry Lake Wildlife Area
    set_key US-8301 KFF-6674  # Ripgut Prairie State Conservation Area
    set_key US-8303 KFF-4963  # Sloan Canyon National Conservation Area
    set_key US-8304 KFF-6376  # McGee Family State Conservation Area
    set_key US-8305 KFF-6851  # Darling State Park
    set_key US-8308 KFF-6390  # Pilot Knob State Conservation Area
    set_key US-8309 KFF-6649  # Dr Harry and Lina Berrier Memorial State Conservation Area
    set_key US-8311 KFF-7181  # Humboldt Wildlife Management Area
    set_key US-8312 KFF-4953  # Gila Box Riparian National Conservation Area
    set_key US-8313 KFF-5648  # Mountains to Sea State Trail
    set_key US-8314 KFF-6386  # Pacific Palisades State Conservation Area
    set_key US-8315 KFF-6397  # Rockwoods State Conservation Area
    set_key US-8319 NIL-0000  # Palisades Interstate State Park (NY); WWFF candidates: KFF-4749, KFF-4750
    set_key US-8326 KFF-5786  # Apalachicola River State Conservation Area
    set_key US-8328 KFF-5794  # Chipola River State Conservation Area
    set_key US-8329 KFF-5795  # Choctawhatchee &amp; Holmes Creek State Conservation Area
    set_key US-8330 KFF-5803  # Econfina Creek State Conservation Area
    set_key US-8332 KFF-5805  # Escambia River State Conservation Area
    set_key US-8333 KFF-5808  # Garcon Point State Conservation Area
    set_key US-8334 KFF-5829  # Perdido River State Conservation Area
    set_key US-8335 KFF-5843  # Yellow River State Conservation Area
    set_key US-8336 KFF-5788  # Bayard State Conservation Area
    set_key US-8337 KFF-6700  # Black Creek Ravines State Conservation Area
    set_key US-8338 KFF-5790  # Blue Cypress State Conservation Area
    set_key US-8339 KFF-5791  # Buck Lake State Conservation Area
    set_key US-8340 KFF-5793  # Canaveral Marshes State Conservation Area
    set_key US-8341 KFF-5797  # Clark Bay State Conservation Area
    set_key US-8342 KFF-5798  # Crescent Lake State Conservation Area
    set_key US-8343 KFF-5800  # Deep Creek State Conservation Area
    set_key US-8344 KFF-5802  # Dunns Creek State Conservation Area
    set_key US-8345 KFF-6092  # Econlockhatchee Sandhills State Conservation Area
    set_key US-8346 KFF-5804  # Emeralda Marsh State Conservation Area
    set_key US-8347 KFF-5806  # Fellsmere Water Management Area State Conservation Area
    set_key US-8348 KFF-5807  # Fort Drum Marsh State Conservation Area
    set_key US-8349 KFF-6712  # Gourd Island State Conservation Area
    set_key US-8351 KFF-5809  # Heart Island State Conservation Area
    set_key US-8352 KFF-6719  # Julington-Durbin Preserve State Conservation Area
    set_key US-8353 KFF-6720  # Lake Apopka North Shore State Conservation Area
    set_key US-8354 KFF-5811  # Lake George State Conservation Area
    set_key US-8355 KFF-5812  # Lake Jesup State Conservation Area
    set_key US-8356 KFF-5813  # Lake Monroe State Conservation Area
    set_key US-8357 KFF-5814  # Lake Norris State Conservation Area
    set_key US-8358 KFF-5816  # Lochloosa Wildlife State Conservation Area
    set_key US-8360 KFF-6099  # Micco Water Management Area State Conservation Area
    set_key US-8361 KFF-5821  # Moses Creek State Conservation Area
    set_key US-8362 KFF-5823  # Murphy Creek State Conservation Area
    set_key US-8364 KFF-6725  # Ocklawaha Prairie Restoration Area
    set_key US-8365 KFF-6726  # Orange Creek Restoration Area
    set_key US-8366 KFF-5826  # Palm Bluff State Conservation Area
    set_key US-8367 KFF-5828  # Pellicer Creek State Conservation Area
    set_key US-8368 KFF-5831  # Rice Creek State Conservation Area
    set_key US-8369 KFF-5832  # River Lakes State Conservation Area
    set_key US-8370 KFF-5835  # Seminole Ranch State Conservation Area
    set_key US-8371 KFF-5836  # Silver Springs Forest State Conservation Area
    set_key US-8372 KFF-6732  # Stokes Landing State Conservation Area
    set_key US-8373 KFF-6577  # Sunnyhill Restoration Area State Conservation Area
    set_key US-8374 KFF-5839  # Thomas Creek State Conservation Area
    set_key US-8375 KFF-5840  # Three Forks State Conservation Area
    set_key US-8376 KFF-5841  # Twelve Mile Swamp State Conservation Area
    set_key US-8378 KFF-5709  # Snakeden Hollow State Wildlife Area
    set_key US-8379 KFF-5710  # Spoon River State Forest
    set_key US-8380 KFF-5711  # Sahara Woods State Recreation Area
    set_key US-8382 KFF-5742  # Rehoboth State Forest
    set_key US-8383 KFF-5755  # Wrentham State Forest
    set_key US-8384 KFF-5762  # Constitution Beach State Park
    set_key US-8385 KFF-5763  # Farnham-Connolly State Park
    set_key US-8386 KFF-5764  # Fort Revere Park State Park
    set_key US-8390 KFF-5765  # Mystic Lakes State Park
    set_key US-8391 KFF-5766  # Quabbin State Park
    set_key US-8392 KFF-5767  # South Cape Beach State Park
    set_key US-8393 KFF-6262  # Stodder's Neck &amp; Abigail Adams State Park
    set_key US-8402 KFF-5691  # Blue Hills State Reserve
    set_key US-8403 KFF-6250  # Breakheart State Reserve
    set_key US-8405 KFF-6251  # Charles River State Reserve
    set_key US-8407 KFF-6252  # Cutler Park State Reserve
    set_key US-8412 KFF-6253  # Horseneck Beach State Reserve
    set_key US-8413 KFF-6254  # Jug End WMA State Reserve
    set_key US-8414 KFF-5690  # Middlesex Fells State Reserve
    set_key US-8415 KFF-6256  # Mount Everett State Reserve
    set_key US-8416 KFF-6258  # Mount Sugarloaf State Reserve
    set_key US-8417 KFF-6259  # Mount Tom State Reserve
    set_key US-8421 KFF-6260  # Neponset River State Reserve
    set_key US-8427 KFF-6261  # Rumney March State Reserve
    set_key US-8431 KFF-6263  # Stony Brook State Reserve
    set_key US-8443 KFF-6264  # Seboomook Lake Property State Preserve
    set_key US-8445 KFF-7283  # Delano Wildlife Management Area
    set_key US-8447 KFF-7285  # Steep Falls Wildlife Management Area
    set_key US-8502 KFF-5696  # Mussel Fork State Conservation Area
    set_key US-8503 KFF-5697  # Union Ridge State Conservation Area
    set_key US-8504 KFF-5698  # Sugar Creek State Conservation Area
    set_key US-8505 KFF-5699  # Indian Hills State Conservation Area
    set_key US-8506 KFF-5700  # Hidden Hollow State Conservation Area
    set_key US-8507 KFF-5701  # LaBarque Creek State Conservation Area
    set_key US-8508 KFF-5702  # Big Creek State Conservation Area
    set_key US-8509 KFF-6681  # Shoemaker State Conservation Area
    set_key US-8510 KFF-6401  # Ruth and Paul Henning State Conservation Area
    set_key US-8511 KFF-6694  # White River Balds Natural Area State Conservation Area
    set_key US-8521 KFF-6623  # Stewart Lake National Wildlife Refuge
    set_key US-8522 KFF-7134  # White Lake National Wildlife Refuge
    set_key US-8582 KFF-7225  # Hofflund Wildlife Management Area
    set_key US-8600 KFF-7222  # Prairie Chicken Wildlife Management Area
    set_key US-8613 KFF-7224  # Wild Rice Wildlife Management Area
    set_key US-8622 KFF-5953  # Carlton Hill State Recreation Area
    set_key US-8624 KFF-5978  # Honeoye Inlet Wildlife Management Area
    set_key US-8626 KFF-5991  # Rattlesnake Hill Wildlife Management Area
    set_key US-8628 KFF-4540  # Caumsett State State Historical Park
    set_key US-8630 KFF-5919  # Tranquility State Wildlife Area
    set_key US-8631 KFF-6453  # Beach City State Wildlife Area
    set_key US-8633 KFF-5921  # Waterloo State Wildlife Area
    set_key US-8634 KFF-6459  # Copper Hollow State Wildlife Area
    set_key US-8636 KFF-5914  # Paint Creek State Wildlife Area
    set_key US-8637 KFF-6461  # Deer Creek State Wildlife Area
    set_key US-8638 KFF-5908  # Indian Creek State Wildlife Area
    set_key US-8652 KFF-5558  # Altus Lugert Wildlife Management Area
    set_key US-8653 KFF-5564  # Ellis County Wildlife Management Area
    set_key US-8655 KFF-7135  # Grady County Wildlife Management Area
    set_key US-8659 KFF-7155  # Sparrowhawk Wildlife Management Area
    set_key US-8675 KFF-5784  # Alapahoochee State Conservation Area
    set_key US-8676 KFF-5792  # Cabbage Creek, Scanlon State Conservation Area
    set_key US-8678 KFF-5799  # Cuba Bay State Conservation Area
    set_key US-8679 KFF-5801  # Devil's Hammock State Conservation Area
    set_key US-8683 KFF-5817  # Guaranto, Log Landing, Suwannee Street State Conservation Area
    set_key US-8684 KFF-6713  # Grady State Conservation Area
    set_key US-8685 KFF-5810  # Holton Creek, Trillium Slopes State Conservation Area
    set_key US-8686 KFF-5787  # Hunter Creek, Belmont, Bay Creek State Conservation Area
    set_key US-8690 KFF-5819  # Mallory Swamp State Conservation Area
    set_key US-8691 KFF-5820  # Mattair Springs, Camp Branch State Conservation Area
    set_key US-8692 KFF-5822  # Mt. Gilead, Lamont State Conservation Area
    set_key US-8694 KFF-5824  # Natural Well Branch State Conservation Area
    set_key US-8695 KFF-5827  # Peacock Slough State Conservation Area
    set_key US-8697 KFF-5830  # R.O Ranch State Conservation Area
    set_key US-8698 KFF-6729  # Ruth-Springs State Conservation Area
    set_key US-8699 KFF-5833  # Sandlin Bay State Conservation Area
    set_key US-8700 KFF-5834  # Santa Fe Swamp, Lake Alto State Conservation Area
    set_key US-8703 KFF-5837  # Steinhatchee Rise/Steinhatchee Falls State Conservation Area
    set_key US-8704 KFF-5838  # Steinhatchee Springs State Conservation Area
    set_key US-8708 KFF-6734  # Swift Creek State Conservation Area
    set_key US-8711 KFF-5815  # Owens Spring, Walker, Adams, Little River State Conservation Area
    set_key US-8713 KFF-6741  # Withlacoochee Hills State Conservation Area
    set_key US-8717 KFF-5785  # Allapattah Flats State Conservation Area
    set_key US-8722 KFF-6100  # PA 012 State Game Land
    set_key US-8723 KFF-6101  # PA 013 State Game Land
    set_key US-8724 KFF-6102  # PA 014 State Game Land
    set_key US-8725 KFF-6103  # PA 024 State Game Land
    set_key US-8726 KFF-6104  # PA 025 State Game Land
    set_key US-8727 KFF-6105  # PA 026 State Game Land
    set_key US-8728 KFF-6106  # PA 028 State Game Land
    set_key US-8729 KFF-6107  # PA 029 State Game Land
    set_key US-8730 KFF-6108  # PA 030 State Game Land
    set_key US-8731 KFF-6109  # PA 031 State Game Land
    set_key US-8732 KFF-6110  # PA 033 State Game Land
    set_key US-8733 KFF-6111  # PA 034 State Game Land
    set_key US-8734 KFF-6112  # PA 035 State Game Land
    set_key US-8735 KFF-6772  # PA 036 State Game Land
    set_key US-8736 KFF-6113  # PA 037 State Game Land
    set_key US-8738 KFF-6114  # PA 039 State Game Land
    set_key US-8739 KFF-6115  # PA 040 State Game Land
    set_key US-8740 KFF-6116  # PA 041 State Game Land
    set_key US-8741 KFF-6033  # PA 042 State Game Land
    set_key US-8742 KFF-5844  # PA 043 State Game Land
    set_key US-8743 KFF-6117  # PA 044 State Game Land
    set_key US-8744 KFF-6118  # PA 045 State Game Land
    set_key US-8745 KFF-5845  # PA 046 State Game Land
    set_key US-8746 KFF-6119  # PA 047 State Game Land
    set_key US-8747 KFF-6120  # PA 048 State Game Land
    set_key US-8748 KFF-6121  # PA 049 State Game Land
    set_key US-8749 KFF-6034  # PA 050 State Game Land
    set_key US-8750 KFF-6035  # PA 051 State Game Land
    set_key US-8751 KFF-5846  # PA 052 State Game Land
    set_key US-8752 KFF-6122  # PA 053 State Game Land
    set_key US-8753 KFF-6123  # PA 054 State Game Land
    set_key US-8754 KFF-6124  # PA 055 State Game Land
    set_key US-8755 KFF-6503  # PA 056 State Game Land
    set_key US-8756 KFF-6125  # PA 057 State Game Land
    set_key US-8757 KFF-6126  # PA 058 State Game Land
    set_key US-8758 KFF-6127  # PA 059 State Game Land
    set_key US-8759 KFF-6128  # PA 060 State Game Land
    set_key US-8760 KFF-6129  # PA 061 State Game Land
    set_key US-8761 KFF-6130  # PA 062 State Game Land
    set_key US-8762 KFF-6131  # PA 063 State Game Land
    set_key US-8763 KFF-6132  # PA 064 State Game Land
    set_key US-8764 KFF-6133  # PA 065 State Game Land
    set_key US-8765 KFF-6773  # PA 066 State Game Land
    set_key US-8766 KFF-6134  # PA 067 State Game Land
    set_key US-8767 KFF-6135  # PA 068 State Game Land
    set_key US-8768 KFF-6136  # PA 069 State Game Land
    set_key US-8769 KFF-6137  # PA 070 State Game Land
    set_key US-8770 KFF-6138  # PA 071 State Game Land
    set_key US-8771 KFF-6139  # PA 072 State Game Land
    set_key US-8772 KFF-6140  # PA 073 State Game Land
    set_key US-8773 KFF-6141  # PA 074 State Game Land
    set_key US-8774 KFF-6142  # PA 075 State Game Land
    set_key US-8775 KFF-6143  # PA 076 State Game Land
    set_key US-8776 KFF-6144  # PA 077 State Game Land
    set_key US-8778 KFF-6145  # PA 079 State Game Land
    set_key US-8779 KFF-5847  # PA 080 State Game Land
    set_key US-8780 KFF-6146  # PA 081 State Game Land
    set_key US-8781 KFF-6147  # PA 082 State Game Land
    set_key US-8782 KFF-5848  # PA 083 State Game Land
    set_key US-8783 KFF-6148  # PA 084 State Game Land
    set_key US-8785 KFF-6149  # PA 086 State Game Land
    set_key US-8786 KFF-6150  # PA 087 State Game Land
    set_key US-8787 KFF-6151  # PA 088 State Game Land
    set_key US-8788 KFF-6152  # PA 089 State Game Land
    set_key US-8789 KFF-6153  # PA 090 State Game Land
    set_key US-8790 KFF-6154  # PA 091 State Game Land
    set_key US-8791 KFF-6155  # PA 092 State Game Land
    set_key US-8792 KFF-6774  # PA 093 State Game Land
    set_key US-8793 KFF-6156  # PA 094 State Game Land
    set_key US-8794 KFF-6157  # PA 095 State Game Land
    set_key US-8795 KFF-6158  # PA 096 State Game Land
    set_key US-8796 KFF-6159  # PA 097 State Game Land
    set_key US-8797 KFF-6504  # PA 098 State Game Land
    set_key US-8798 KFF-6160  # PA 099 State Game Land
    set_key US-8799 KFF-6161  # PA 100 State Game Land
    set_key US-8800 KFF-6162  # PA 101 State Game Land
    set_key US-8802 KFF-6163  # PA 103 State Game Land
    set_key US-8803 KFF-6164  # PA 104 State Game Land
    set_key US-8804 KFF-6165  # PA 105 State Game Land
    set_key US-8805 KFF-5849  # PA 106 State Game Land
    set_key US-8806 KFF-6166  # PA 107 State Game Land
    set_key US-8807 KFF-6167  # PA 108 State Game Land
    set_key US-8808 KFF-6505  # PA 109 State Game Land
    set_key US-8809 KFF-5850  # PA 110 State Game Land
    set_key US-8810 KFF-6036  # PA 111 State Game Land
    set_key US-8811 KFF-6168  # PA 112 State Game Land
    set_key US-8812 KFF-6775  # PA 113 State Game Land
    set_key US-8813 KFF-6169  # PA 114 State Game Land
    set_key US-8814 KFF-6506  # PA 115 State Game Land
    set_key US-8815 KFF-6170  # PA 116 State Game Land
    set_key US-8816 KFF-6171  # PA 117 State Game Land
    set_key US-8817 KFF-6172  # PA 118 State Game Land
    set_key US-8818 KFF-6173  # PA 119 State Game Land
    set_key US-8819 KFF-6174  # PA 120 State Game Land
    set_key US-8820 KFF-6175  # PA 121 State Game Land
    set_key US-8821 KFF-6176  # PA 122 State Game Land
    set_key US-8822 KFF-6507  # PA 123 State Game Land
    set_key US-8823 KFF-6177  # PA 124 State Game Land
    set_key US-8825 KFF-6178  # PA 127 State Game Land
    set_key US-8826 KFF-6508  # PA 128 State Game Land
    set_key US-8827 KFF-6179  # PA 129 State Game Land
    set_key US-8828 KFF-6180  # PA 130 State Game Land
    set_key US-8830 KFF-6509  # PA 132 State Game Land
    set_key US-8831 KFF-6181  # PA 133 State Game Land
    set_key US-8832 KFF-6182  # PA 134 State Game Land
    set_key US-8833 KFF-6183  # PA 135 State Game Land
    set_key US-8835 KFF-6510  # PA 137 State Game Land
    set_key US-8836 KFF-6184  # PA 138 State Game Land
    set_key US-8838 KFF-6776  # PA 140 State Game Land
    set_key US-8839 KFF-6185  # PA 141 State Game Land
    set_key US-8841 KFF-6186  # PA 143 State Game Land
    set_key US-8842 KFF-6777  # PA 144 State Game Land
    set_key US-8843 KFF-5851  # PA 145 State Game Land
    set_key US-8844 KFF-6778  # PA 146 State Game Land
    set_key US-8845 KFF-6187  # PA 147 State Game Land
    set_key US-8846 KFF-6779  # PA 148 State Game Land
    set_key US-8847 KFF-6511  # PA 149 State Game Land
    set_key US-8848 KFF-6780  # PA 150 State Game Land
    set_key US-8849 KFF-6512  # PA 151 State Game Land
    set_key US-8850 KFF-6781  # PA 152 State Game Land
    set_key US-8851 KFF-6037  # PA 153 State Game Land
    set_key US-8852 KFF-6513  # PA 154 State Game Land
    set_key US-8854 KFF-5852  # PA 056 State Game Land
    set_key US-8855 KFF-5853  # PA 157 State Game Land
    set_key US-8856 KFF-6188  # PA 158 State Game Land
    set_key US-8857 KFF-6189  # PA 159 State Game Land
    set_key US-8858 KFF-5854  # PA 160 State Game Land
    set_key US-8860 KFF-6514  # PA 162 State Game Land
    set_key US-8863 KFF-6515  # PA 165 State Game Land
    set_key US-8864 KFF-6190  # PA 166 State Game Land
    set_key US-8865 KFF-6782  # PA 167 State Game Land
    set_key US-8866 KFF-6191  # PA 168 State Game Land
    set_key US-8867 KFF-6192  # PA 169 State Game Land
    set_key US-8868 KFF-6193  # PA 170 State Game Land
    set_key US-8869 KFF-6516  # PA 171 State Game Land
    set_key US-8870 KFF-6783  # PA 172 State Game Land
    set_key US-8871 KFF-6517  # PA 173 State Game Land
    set_key US-8872 KFF-6194  # PA 174 State Game Land
    set_key US-8873 KFF-6784  # PA 175 State Game Land
    set_key US-8874 KFF-6195  # PA 176 State Game Land
    set_key US-8876 KFF-6196  # PA 179 State Game Land
    set_key US-8877 KFF-6197  # PA 180 State Game Land
    set_key US-8878 KFF-5855  # PA 181 State Game Land
    set_key US-8880 KFF-6198  # PA 183 State Game Land
    set_key US-8881 KFF-6199  # PA 184 State Game Land
    set_key US-8882 KFF-6785  # PA 185 State Game Land
    set_key US-8883 KFF-6786  # PA 186 State Game Land
    set_key US-8884 KFF-6200  # PA 187 State Game Land
    set_key US-8885 KFF-6518  # PA 188 State Game Land
    set_key US-8888 KFF-6519  # PA 191 State Game Land
    set_key US-8891 KFF-6787  # PA 194 State Game Land
    set_key US-8892 KFF-6201  # PA 195 State Game Land
    set_key US-8894 KFF-6520  # PA 197 State Game Land
    set_key US-8895 KFF-6202  # PA 198 State Game Land
    set_key US-8896 KFF-6521  # PA 199 State Game Land
    set_key US-8899 KFF-6788  # PA 202 State Game Land
    set_key US-8900 KFF-6522  # PA 203 State Game Land
    set_key US-8901 KFF-6203  # PA 204 State Game Land
    set_key US-8902 KFF-5856  # PA 205 State Game Land
    set_key US-8903 KFF-6523  # PA 206 State Game Land
    set_key US-8904 KFF-6204  # PA 207 State Game Land
    set_key US-8905 KFF-6205  # PA 208 State Game Land
    set_key US-8906 KFF-6206  # PA 209 State Game Land
    set_key US-8907 KFF-5857  # PA 210 State Game Land
    set_key US-8908 KFF-5858  # PA 211 State Game Land
    set_key US-8909 KFF-6789  # PA 212 State Game Land
    set_key US-8910 KFF-6207  # PA 213 State Game Land
    set_key US-8911 KFF-6208  # PA 214 State Game Land
    set_key US-8912 KFF-6524  # PA 215 State Game Land
    set_key US-8914 KFF-5859  # PA 217 State Game Land
    set_key US-8915 KFF-6525  # PA 218 State Game Land
    set_key US-8916 KFF-6209  # PA 219 State Game Land
    set_key US-8918 KFF-6210  # PA 221 State Game Land
    set_key US-8919 KFF-6211  # PA 222 State Game Land
    set_key US-8920 KFF-6212  # PA 223 State Game Land
    set_key US-8921 KFF-6790  # PA 224 State Game Land
    set_key US-8923 KFF-6791  # PA 226 State Game Land
    set_key US-8924 KFF-6526  # PA 227 State Game Land
    set_key US-8925 KFF-6213  # PA 228 State Game Land
    set_key US-8926 KFF-5860  # PA 229 State Game Land
    set_key US-8927 KFF-6527  # PA 230 State Game Land
    set_key US-8929 KFF-6214  # PA 232 State Game Land
    set_key US-8930 KFF-6792  # PA 233 State Game Land
    set_key US-8931 KFF-5861  # PA 234 State Game Land
    set_key US-8932 KFF-6215  # PA 235 State Game Land
    set_key US-8933 KFF-6216  # PA 236 State Game Land
    set_key US-8935 KFF-6793  # PA 238 State Game Land
    set_key US-8936 KFF-6794  # PA 239 State Game Land
    set_key US-8937 KFF-6528  # PA 242 State Game Land
    set_key US-8938 KFF-6529  # PA 243 State Game Land
    set_key US-8939 KFF-6217  # PA 244 State Game Land
    set_key US-8940 KFF-6218  # PA 245 State Game Land
    set_key US-8941 KFF-5862  # PA 246 State Game Land
    set_key US-8943 KFF-6795  # PA 248 State Game Land
    set_key US-8944 KFF-6530  # PA 249 State Game Land
    set_key US-8946 KFF-6219  # PA 251 State Game Land
    set_key US-8947 KFF-6220  # PA 252 State Game Land
    set_key US-8948 KFF-6796  # PA 253 State Game Land
    set_key US-8949 KFF-6531  # PA 254 State Game Land
    set_key US-8950 KFF-6221  # PA 255 State Game Land
    set_key US-8951 KFF-6532  # PA 256 State Game Land
    set_key US-8952 KFF-5863  # PA 257 State Game Land
    set_key US-8953 KFF-6797  # PA 258 State Game Land
    set_key US-8955 KFF-6222  # PA 260 State Game Land
    set_key US-8956 KFF-6223  # PA 261 State Game Land
    set_key US-8957 KFF-6224  # PA 262 State Game Land
    set_key US-8958 KFF-6798  # PA 263 State Game Land
    set_key US-8959 KFF-6225  # PA 264 State Game Land
    set_key US-8960 KFF-6799  # PA 265 State Game Land
    set_key US-8962 KFF-6533  # PA 267 State Game Land
    set_key US-8963 KFF-6226  # PA 268 State Game Land
    set_key US-8964 KFF-6800  # PA 269 State Game Land
    set_key US-8965 KFF-6227  # PA 270 State Game Land
    set_key US-8966 KFF-6534  # PA 271 State Game Land
    set_key US-8968 KFF-6801  # PA 273 State Game Land
    set_key US-8969 KFF-6802  # PA 274 State Game Land
    set_key US-8970 KFF-6038  # PA 276 State Game Land
    set_key US-8971 KFF-6535  # PA 277 State Game Land
    set_key US-8972 KFF-6536  # PA 278 State Game Land
    set_key US-8974 KFF-5864  # PA 280 State Game Land
    set_key US-8975 KFF-6537  # PA 281 State Game Land
    set_key US-8977 KFF-6228  # PA 283 State Game Land
    set_key US-8978 KFF-6538  # PA 284 State Game Land
    set_key US-8979 KFF-6229  # PA 285 State Game Land
    set_key US-8980 KFF-5865  # PA 286 State Game Land
    set_key US-8981 KFF-6230  # PA 287 State Game Land
    set_key US-8982 KFF-6539  # PA 289 State Game Land
    set_key US-8983 KFF-6540  # PA 290 State Game Land
    set_key US-8984 KFF-6541  # PA 291 State Game Land
    set_key US-8985 KFF-6803  # PA 292 State Game Land
    set_key US-8986 KFF-6231  # PA 293 State Game Land
    set_key US-8988 KFF-6232  # PA 295 State Game Land
    set_key US-8989 KFF-6233  # PA 296 State Game Land
    set_key US-8990 KFF-6804  # PA 297 State Game Land
    set_key US-8991 KFF-6542  # PA 298 State Game Land
    set_key US-8992 KFF-6234  # PA 299 State Game Land
    set_key US-8993 KFF-6235  # PA 300 State Game Land
    set_key US-8994 KFF-6236  # PA 301 State Game Land
    set_key US-8995 KFF-6237  # PA 302 State Game Land
    set_key US-8997 KFF-6805  # PA 305 State Game Land
    set_key US-8998 KFF-6543  # PA 306 State Game Land
    set_key US-8999 KFF-6544  # PA 307 State Game Land
    set_key US-9000 KFF-6806  # PA 309 State Game Land
    set_key US-9001 KFF-6545  # PA 310 State Game Land
    set_key US-9002 KFF-6238  # PA 311 State Game Land
    set_key US-9003 KFF-6239  # PA 312 State Game Land
    set_key US-9005 KFF-6240  # PA 314 State Game Land
    set_key US-9007 KFF-6241  # PA 316 State Game Land
    set_key US-9008 KFF-6546  # PA 317 State Game Land
    set_key US-9009 KFF-6807  # PA 318 State Game Land
    set_key US-9011 KFF-6242  # PA 321 State Game Land
    set_key US-9012 KFF-6243  # PA 322 State Game Land
    set_key US-9013 KFF-6244  # PA 323 State Game Land
    set_key US-9015 KFF-6808  # PA 325 State Game Land
    set_key US-9016 KFF-6245  # PA 326 State Game Land
    set_key US-9018 KFF-6809  # PA 328 State Game Land
    set_key US-9019 KFF-6547  # PA 329 State Game Land
    set_key US-9020 KFF-6246  # PA 330 State Game Land
    set_key US-9021 KFF-6247  # PA 331 State Game Land
    set_key US-9022 KFF-6548  # PA 333 State Game Land
    set_key US-9023 KFF-6249  # PA 334 State Game Land
    set_key US-9024 KFF-6549  # PA 335 State Game Land
    set_key US-9025 KFF-5971  # Erwin Wildlife Management Area
    set_key US-9028 KFF-5965  # Conesus Inlet Wildlife Management Area
    set_key US-9034 KFF-6001  # West Cameron Wildlife Management Area
    set_key US-9036 KFF-7142  # Alder Bottom Wildlife Management Area
    set_key US-9037 KFF-5955  # Allegheny Reservoir Wildlife Management Area
    set_key US-9039 KFF-5960  # Canadaway Creek Wildlife Management Area
    set_key US-9044 KFF-5967  # Conewango Swamp Wildlife Management Area
    set_key US-9046 KFF-7147  # Genesee Valley Wildlife Management Area
    set_key US-9049 KFF-5975  # Hanging Bog Wildlife Management Area
    set_key US-9060 KFF-6000  # Watts Flats Wildlife Management Area
    set_key US-9061 KFF-5964  # Cicero Swamp Wildlife Management Area
    set_key US-9062 KFF-5966  # Connecticut Hill Wildlife Management Area
    set_key US-9065 KFF-5969  # Deer Creek Marsh Wildlife Management Area
    set_key US-9066 KFF-5974  # Hamlin Marsh Wildlife Management Area
    set_key US-9067 KFF-5976  # Happy Valley Wildlife Management Area
    set_key US-9068 KFF-5983  # Little John Wildlife Management Area
    set_key US-9070 KFF-5989  # Pharsalia Wildlife Management Area
    set_key US-9071 KFF-5994  # Three Mile Bay Wildlife Management Area
    set_key US-9073 KFF-5996  # Tioughnioga Wildlife Management Area
    set_key US-9080 KFF-5977  # High Tor Wildlife Management Area
    set_key US-9082 KFF-5980  # Lake Shore Marshes Wildlife Management Area
    set_key US-9083 KFF-5985  # Northern Montezuma Wildlife Management Area
    set_key US-9087 KFF-5956  # Ashland Flats Wildlife Management Area
    set_key US-9088 KFF-7156  # Black Pond Wildlife Management Area
    set_key US-9091 KFF-5970  # Dexter Marsh Wildlife Management Area
    set_key US-9092 KFF-5972  # Fish Creek Wildlife Management Area
    set_key US-9093 KFF-5973  # French Creek Wildlife Management Area
    set_key US-9095 KFF-7138  # Indian River Wildlife Management Area
    set_key US-9096 KFF-5981  # Lakeview Wildlife Management Area
    set_key US-9097 KFF-7144  # Oriskany Flats Wildlife Management Area
    set_key US-9098 KFF-5988  # Perch River Wildlife Management Area
    set_key US-9100 KFF-5990  # Point Peninsula Wildlife Management Area
    set_key US-9103 KFF-5998  # Tug Hill Wildlife Management Area
    set_key US-9104 KFF-5999  # Upper and Lower Lakes Wildlife Management Area
    set_key US-9106 KFF-6002  # Wilson Hill Wildlife Management Area
    set_key US-9107 KFF-7150  # Ausable Marsh Wildlife Management Area
    set_key US-9109 KFF-5963  # Chazy Highlands Wildlife Management Area
    set_key US-9111 KFF-7149  # Kings Bay Wildlife Management Area
    set_key US-9112 KFF-5979  # Lake Alice Wildlife Management Area
    set_key US-9113 KFF-5982  # Lewis Preserve Wildlife Management Area
    set_key US-9117 KFF-5992  # Saratoga Sand Plains Wildlife Management Area
    set_key US-9120 KFF-7141  # Wickham Marsh Wildlife Management Area
    set_key US-9121 KFF-5958  # Bear Spring Mountain Wildlife Management Area
    set_key US-9123 KFF-5961  # Capital District Wildlife Management Area
    set_key US-9130 KFF-5987  # Partridge Run Wildlife Management Area
    set_key US-9136 KFF-5957  # Bashakill Wildlife Management Area
    set_key US-9138 KFF-5968  # Cranberry Mountain Wildlife Management Area
    set_key US-9140 KFF-5984  # Mongaup Valley Wildlife Management Area
    set_key US-9152 KFF-4971  # TouVelle State Park State Recreation Area
    set_key US-9156 KFF-6559  # Crooked River National Wild and Scenic River
    set_key US-9157 KFF-4975  # Donner und Blitzen National Wild and Scenic River
    set_key US-9158 KFF-6561  # John Day National Wild and Scenic River
    set_key US-9159 KFF-6560  # Lower Deschutes National Wild and Scenic River
    set_key US-9160 KFF-4977  # Steens Mountain Cooperative Management and Protected Area
    set_key US-9199 KFF-5600  # Hatchery Wildlife Management Area
    set_key US-9202 KFF-5609  # Santee Coastal Reserve Wildlife Management Area
    set_key US-9206 KFF-5599  # Donnelley Wildlife Management Area
    set_key US-9214 KFF-5608  # Palachucola Wildlife Management Area
    set_key US-9215 KFF-5613  # Webb Wildlife Center Wildlife Management Area
    set_key US-9217 KFF-5611  # Waccamaw River Wildlife Management Area
    set_key US-9218 KFF-5603  # Liberty Hill Wildlife Management Area
    set_key US-9219 KFF-5595  # Belfast Wildlife Management Area
    set_key US-9225 KFF-5596  # Brasstown Creek Wildlife Management Area
    set_key US-9226 KFF-5601  # Jocassee Gorges Wildlife Management Area
    set_key US-9231 KFF-5694  # Utahraptor State Park
    set_key US-9232 KFF-5695  # Lost Creek State Park
    set_key US-9235 KFF-7389  # Arrow Canyon Wilderness Area
    set_key US-9239 KFF-4961  # Black Rock Desert - High Rock Canyon Emigrant Trails National Conservation Area
    set_key US-9278 KFF-7390  # Rainbow Mountain Wilderness Area
    set_key US-9285 KFF-6554  # Spirit Mountain (Avi Kwa Ame) National Monument
    set_key US-9309 KFF-7265  # St Mary's Island Wildlife Management Area
    set_key US-9393 KFF-6443  # Blackhand Gorge State Nature Preserve
    set_key US-9394 KFF-6444  # Boch Hollow State Nature Preserve
    set_key US-9397 KFF-6445  # Christmas Rocks State Nature Preserve
    set_key US-9404 KFF-6768  # Desonier State Nature Preserve
    set_key US-9419 KFF-5911  # Lake Katharine State Nature Preserve
    set_key US-9420 KFF-6448  # Lawrence Woods State Nature Preserve
    set_key US-9425 KFF-6450  # Old Woman Creek (Nerr) State Nature Preserve
    set_key US-9438 KFF-6451  # Tinkers Creek State Nature Preserve
    set_key US-9443 KFF-6452  # Ales Run State Wildlife Area
    set_key US-9444 KFF-6765  # Andreoff State Wildlife Area
    set_key US-9447 KFF-6813  # Broken ARO State Wildlife Area
    set_key US-9449 KFF-6455  # Brush Creek State Wildlife Area
    set_key US-9450 KFF-6457  # Camp Belden State Wildlife Area
    set_key US-9453 KFF-6458  # Coalton State Wildlife Area
    set_key US-9454 KFF-6460  # Crown City State Wildlife Area
    set_key US-9456 KFF-5951  # Delaware State Wildlife Area
    set_key US-9458 KFF-6462  # Dillon State Wildlife Area
    set_key US-9459 KFF-6463  # Dorset State Wildlife Area
    set_key US-9460 KFF-6769  # Eagle Creek State Wildlife Area
    set_key US-9461 KFF-6466  # Fallsville State Wildlife Area
    set_key US-9464 NIL-0000  # Flint Run State Wildlife Area; WWFF candidates: KFF-6467, KFF-6767
    set_key US-9466 KFF-6770  # Grand River State Wildlife Area
    set_key US-9468 KFF-6469  # Hambden Orchard State Wildlife Area
    set_key US-9469 KFF-6470  # Highlandtown State Wildlife Area
    set_key US-9470 KFF-5909  # Jockey Hollow State Wildlife Area
    set_key US-9472 KFF-5910  # Kokosing Lake State Wildlife Area
    set_key US-9473 KFF-6897  # Lake Park State Wildlife Area
    set_key US-9480 KFF-6474  # Mercer State Wildlife Area
    set_key US-9481 KFF-6475  # Metzger Marsh State Wildlife Area
    set_key US-9484 KFF-5912  # Monroe Lake State Wildlife Area
    set_key US-9485 KFF-5913  # Mosquito Creek State Wildlife Area
    set_key US-9487 KFF-6476  # New Lyme State Wildlife Area
    set_key US-9493 KFF-5915  # Pickerel Creek State Wildlife Area
    set_key US-9494 KFF-6477  # Pleasant Valley State Wildlife Area
    set_key US-9495 KFF-5916  # Powelson State Wildlife Area
    set_key US-9496 KFF-6478  # Resthaven State Wildlife Area
    set_key US-9497 KFF-6479  # Ross Lake State Wildlife Area
    set_key US-9498 KFF-5917  # Rush Run State Wildlife Area
    set_key US-9499 KFF-6480  # Salt Fork State Wildlife Area
    set_key US-9500 KFF-5918  # Shenango State Wildlife Area
    set_key US-9501 KFF-6481  # Simco State Wildlife Area
    set_key US-9502 KFF-6482  # Spencer Lake State Wildlife Area
    set_key US-9505 KFF-6484  # Superior State Wildlife Area
    set_key US-9510 KFF-6486  # Tycoon Lake State Wildlife Area
    set_key US-9511 KFF-6771  # Urbana State Wildlife Area
    set_key US-9514 KFF-5920  # Wallace H. O'Dowd State Wildlife Area
    set_key US-9516 KFF-5922  # Wellston State Wildlife Area
    set_key US-9517 KFF-6488  # Willow Point State Wildlife Area
    set_key US-9518 KFF-6489  # Wingfoot State Wildlife Area
    set_key US-9519 KFF-6490  # Wolf Creek State Wildlife Area
    set_key US-9520 KFF-6492  # Woodland Trails State Wildlife Area
    set_key US-9522 KFF-6493  # Zepernick State Wildlife Area
    set_key US-9558 KFF-6841  # John B. Yeon State Park
    set_key US-9559 KFF-6842  # Lost Creek State Park
    set_key US-9565 KFF-6843  # Mongold State Park
    set_key US-9593 KFF-4957  # Dominguez-Escalante BLM National Conservation Area
    set_key US-9594 KFF-4958  # Gunnison Gorge BLM National Conservation Area
    set_key US-9595 KFF-4959  # McInnis Canyons BLM National Conservation Area
    set_key US-9597 NIL-0000  # Kremmling BLM National Recreation Area
    set_key US-9598 NIL-0000  # Hardscrabble-East Eagle BLM National Recreation Area
    set_key US-9599 NIL-0000  # Wolford Mountain and Dam Site BLM National Recreation Area
    set_key US-9601 KFF-7203  # 63 Ranch State Wildlife Area
    set_key US-9602 NIL-0000  # Adams State Wildlife Area
    set_key US-9603 KFF-7198  # Adobe Creek Res. (Blue Lake) State Wildlife Area
    set_key US-9605 NIL-0000  # Alma State Wildlife Area
    set_key US-9607 KFF-7169  # Apishapa State Wildlife Area
    set_key US-9609 KFF-7172  # Basalt State Wildlife Area
    set_key US-9612 NIL-0000  # Bellaire Lake State Wildlife Area
    set_key US-9613 KFF-7173  # Bergen Peak State Wildlife Area
    set_key US-9615 NIL-0000  # Big Thompson Ponds State Wildlife Area
    set_key US-9617 KFF-7174  # Bitter Brush State Wildlife Area
    set_key US-9619 NIL-0000  # Blue River State Wildlife Area
    set_key US-9623 NIL-0000  # Bravo State Wildlife Area
    set_key US-9626 KFF-7208  # Brush State Wildlife Area
    set_key US-9627 NIL-0000  # Burchfield State Wildlife Area
    set_key US-9629 NIL-0000  # Cherokee State Wildlife Area
    set_key US-9632 KFF-7196  # Cochetopa State Wildlife Area
    set_key US-9634 KFF-7209  # Coller State Wildlife Area
    set_key US-9636 KFF-7205  # Cottonwood State Wildlife Area
    set_key US-9639 NIL-0000  # Deadman State Wildlife Area
    set_key US-9640 KFF-7199  # Delaney Butte Lakes State Wildlife Area
    set_key US-9644 NIL-0000  # Dowdy Lake State Wildlife Area
    set_key US-9646 NIL-0000  # Duck Creek State Wildlife Area
    set_key US-9649 NIL-0000  # Fort Lyon State Wildlife Area
    set_key US-9650 NIL-0000  # Four Mile State Wildlife Area
    set_key US-9651 NIL-0000  # Frenchman Creek State Wildlife Area
    set_key US-9652 NIL-0000  # Grenada State Wildlife Area
    set_key US-9653 NIL-0000  # Gypsum Ponds State Wildlife Area
    set_key US-9655 NIL-0000  # Holbrook Reservoir State Wildlife Area
    set_key US-9656 NIL-0000  # Holyoke State Wildlife Area
    set_key US-9657 KFF-7200  # Horse Creek Reservoir State Wildlife Area
    set_key US-9663 NIL-0000  # Pony Express State Wildlife Area
    set_key US-9664 NIL-0000  # Prewitt Reservoir State Wildlife Area
    set_key US-9665 NIL-0000  # Queens State Wildlife Area
    set_key US-9666 NIL-0000  # Rosemont State Wildlife Area
    set_key US-9668 NIL-0000  # Sand Draw State Wildlife Area
    set_key US-9669 NIL-0000  # Sawhill Ponds State Wildlife Area
    set_key US-9670 NIL-0000  # Sedgwick Bar State Wildlife Area
    set_key US-9673 NIL-0000  # Timpas Creek State Wildlife Area
    set_key US-9675 NIL-0000  # Two Buttes State Wildlife Area
    set_key US-9678 NIL-0000  # Windy Gap Watchable State Wildlife Area
    set_key US-9679 KFF-5768  # Pecos Canyon State Park
    set_key US-9682 KFF-7392  # Walker River State Recreation Area
    set_key US-9683 NIL-0000  # Amache National Historic Site
    set_key US-9684 KFF-6088  # Sojourner Truth State Park
    set_key US-9685 KFF-6939  # Rio De La Mina National Wild and Scenic River
    set_key US-9686 KFF-6940  # Rio Icacos National Wild and Scenic River
    set_key US-9687 KFF-6941  # Rio Mameyes National Wild and Scenic River
    set_key US-9696 KFF-6568  # Anchorage Coastal Wildlife Refuge
    set_key US-9698 KFF-6571  # Goose Bay Wildlife Refuge
    set_key US-9701 KFF-6570  # Palmer Hay Flats Wildlife Refuge
    set_key US-9704 KFF-6089  # Lizard Mound State Park
    set_key US-9718 KFF-6096  # Savage Gulf State Park
    set_key US-9719 KFF-6094  # Susquehanna Riverlands State Park
    set_key US-9720 KFF-6095  # Vosburg Neck State Park
    set_key US-9721 KFF-6093  # Big Elk Creek State Park
    set_key US-9743 KFF-5687  # Tomblin Wildlife Management Area
    set_key US-9753 KFF-6829  # Katy Trail Rock Island Spur
    set_key US-9755 KFF-6856  # Summersville Lake State Park
    set_key US-9758 NIL-0000  # Chattooga National Wild and Scenic River (SC); WWFF candidates: KFF-6743, KFF-6745, KFF-6748
    set_key US-9759 KFF-6846  # May Forest State Park
    set_key US-9760 KFF-7276  # Bussey Brake Wildlife Management Area
    set_key US-9761 KFF-7277  # Elmer’s Island Wildlife Refuge
    set_key US-9847 KFF-6830  # Clark Creek Natural Area
    set_key US-9873 KFF-7212  # Boone Forks State Wildlife Area
    set_key US-9882 KFF-5621  # Little Creek State Wildlife Area
    set_key US-9894 KFF-5358  # Topsmead State Forest
    set_key US-9912 KFF-7241  # Blue Spring Wildlife Management Area
    set_key US-9924 KFF-6971  # Oakmulgee Wildlife Management Area
    set_key US-9928 KFF-4853  # Devil's Backbone State Forest (CLOSED TO PUBLIC)
    set_key US-9930 KFF-4860  # Old Flat State Forest
    set_key US-9936 KFF-6849  # Sweet Run State Park
    set_key US-9975 KFF-7210  # Iowa River Corridor State Wildlife Area
    set_key US-9985 KFF-6947  # Whychus Creek National Wild and Scenic River
    set_key VI-0000 KFF-0617  # Green Cay National Wildlife Refuge
    set_key VI-0001 KFF-0066  # Virgin Islands National Park
    set_key VI-0002 KFF-0616  # Buck Island National Wildlife Refuge
    set_key VI-0004 KFF-0618  # Sandy Point National Wildlife Refuge
    set_key VI-0005 KFF-0755  # Salt River Bay National Historical Park
    set_key VI-0007 KFF-0906  # Buck Island Reef National Monument
    set_key VI-0008 KFF-0968  # Virgin Islands Coral Reef National Monument
}

# Function to set or update a key-value pair
set_key() {
    local key="$1"
    local value="$2"
    local found=0

    if [[ "${initializing_keys:-0}" == 1 ]]; then
        kv_store+=("$key=$value")
        return
    fi

    for i in "${!kv_store[@]}"; do
        if [[ "${kv_store[$i]}" == "$key="* ]]; then
            kv_store[$i]="$key=$value"
            found=1
            break
        fi
    done

    if [[ $found -eq 0 ]]; then
        kv_store+=("$key=$value")
    fi
}

# Function to get the value for a given key
get_key() {
    local key="$1"
    for pair in "${kv_store[@]}"; do
        if [[ "$pair" == "$key="* ]]; then
            echo "${pair#*=}"
            return
        fi
    done
    echo "null"
}

# Function to delete a key-value pair
delete_key() {
    local key="$1"
    for i in "${!kv_store[@]}"; do
        if [[ "${kv_store[$i]}" == "$key="* ]]; then
            unset kv_store[$i]
            kv_store=("${kv_store[@]}")
            echo "Key deleted."
            return
        fi
    done
    echo "Key not found."
}

# Function to list all key-value pairs
list_keys() {
    for pair in "${kv_store[@]}"; do
        echo "$pair"
    done
}

BASH_SCRIPT_FILENAME=$(basename "$0")
INPUT="input.adi"
DATE=$(date +"%Y%m%d")
WWFF_PARK=$1

# Function to display help
function displayHelp() {
    clear
    echo "$BASH_SCRIPT_FILENAME"
    echo ""
    echo -e "${ORANGE}NAME${NOCOLOR}"
    echo "     ./$BASH_SCRIPT_FILENAME – Creates a cleansed POTA and WWFF file from a hamrs adif file."
    echo ""
    echo -e "${ORANGE}SYNOPSIS${NOCOLOR}"
    echo "     ./$BASH_SCRIPT_FILENAME"
    echo "     ./$BASH_SCRIPT_FILENAME <WWFF Park Reference>"
    echo "     ./$BASH_SCRIPT_FILENAME skip"
    echo "     ./$BASH_SCRIPT_FILENAME help"
    echo ""
    echo -e "${ORANGE}DESCRIPTION${NOCOLOR}"
    echo "     Input file: $INPUT"
    echo ""
    echo "     This script cleanses POTA and WWFF files by adding specific metadata."
    echo "     - Adds MY_POTA_REF:<POTA_PARK> to POTA comments."
    echo "     - Adds MY_WWFF_REF:<WWFF_PARK>, my_sig, and my_sig_info to WWFF comments."
    echo ""
    echo "     If no parameter is passed in, then the script will attempt to process the WWFF file"
    echo "     by an internal lookup."
    echo ""
    echo "     If text other than the below is passed in, then the script will process the WWFF file"
    echo "     using this text as the WWFF identifier. KFF-1212, for example."
    echo ""
    echo -e "     ${ORANGE}skip${NOCOLOR}                     Do not process a WWFF file."
    echo -e "     ${ORANGE}help${NOCOLOR}                     Display the help message."
}

# Function to check and delete existing files
function checkAndDeleteFile() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "${RED}$file exists. Deleting...${NOCOLOR}"
        rm "$file"
    fi
}

# Function to extract callsign from a QSO record
extract_call_from_record() {
    local record="$1"
    local call="UNKNOWN"

    if [[ "$record" =~ \<CALL:[0-9]+\>([^[:space:]<]+) ]]; then
        call="${BASH_REMATCH[1]}"
    fi

    echo "$call"
}

# Function to list callsigns/QSOs that are missing a required field.
# This checks per QSO record, not just raw line counts.
list_calls_missing_field() {
    local FILE="$1"
    local FIELD="$2"

    local record=""
    local qso_number=0
    local missing_count=0
    local call="UNKNOWN"

    while IFS= read -r line || [[ -n "$line" ]]; do
        record+="$line"$'\n'

        if [[ "$line" == *"$EOR_KEY"* ]]; then
            ((qso_number++))

            if [[ "$record" != *"$FIELD"* ]]; then
                call=$(extract_call_from_record "$record")
                echo -e "   ${RED}QSO #$qso_number, callsign: $call is missing $FIELD${NOCOLOR}"
                ((missing_count++))
            fi

            record=""
        fi
    done < "$FILE"

    # Handles a final record if the file does not end with <EOR>
    if [[ -n "$record" ]]; then
        ((qso_number++))
        if [[ "$record" != *"$FIELD"* ]]; then
            call=$(extract_call_from_record "$record")
            echo -e "   ${RED}QSO #$qso_number, callsign: $call is missing $FIELD${NOCOLOR}"
            ((missing_count++))
        fi
    fi

    if [[ "$missing_count" -eq 0 ]]; then
        echo "   No specific QSO found missing $FIELD. This may be caused by duplicate fields, malformed records, or field text split unexpectedly."
    fi
}

# Extract and list unique states from an ADIF log
list_adif_states() {
    local adif_file="$1"

    if [[ ! -f "$adif_file" ]]; then
        echo "Error: File '$adif_file' not found."
        return 1
    fi

    local all_states=(
        AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN
        MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA
        WA WV WI WY
    )

    local contacted_states=($(grep -oi '<state:[0-9]*>[^<]*' "$adif_file" | \
                              sed -E 's/<state:[0-9]+>//I' | \
                              sort | uniq))

    local output=""
    local state_count=0

    output+="  "
    for state in "${all_states[@]}"; do
        if [[ "$state" == "MO" ]]; then
            output+=$(echo -e "${WHITE}MO${NOCOLOR}\n\r  ")
        elif [[ " ${contacted_states[@]} " =~ " ${state} " ]]; then
            output+=$(echo -e "${WHITE}$state${NOCOLOR} ")
            state_count=$((state_count + 1))
        else
            output+=$(echo -e "${DARKGREY}$state${NOCOLOR} ")
        fi
    done

    echo -e "$state_count U.S. States"
    echo -e "$output"

    for state in "${contacted_states[@]}"; do
        echo -n "$state:"
        state_count=$(grep -i "<state:2>$state" "$adif_file" | wc -l)
        trimmed="${state_count#"${state_count%%[![:space:]]*}"}"
        echo "$trimmed"
    done

    return 0
}

# Calculate run time
calculate_time_diff() {
    local adif_file="$1"

    if [[ ! -f "$adif_file" ]]; then
        echo "File not found: $adif_file"
        return 1
    fi

    local first_time last_time first_timestamp last_timestamp time_diff hours minutes seconds total_contacts total_minutes cpm

    total_contacts=$(grep -iEo '<TIME_ON:[0-9]+>[0-9]+' "$adif_file" | wc -l)

    if [[ $total_contacts -lt 1 ]]; then
        echo "No contacts found in the file."
        return 1
    fi

    first_time=$(grep -iEo '<TIME_ON:[0-9]+>[0-9]+' "$adif_file" | head -n 1 | sed 's/.*>//')
    last_time=$(grep -iEo '<TIME_ON:[0-9]+>[0-9]+' "$adif_file" | tail -n 1 | sed 's/.*>//')

    if [[ -z "$first_time" || -z "$last_time" ]]; then
        echo "No TIME_ON entries found in the file."
        return 1
    fi

    first_timestamp=$(date -j -f "%T" "${first_time:0:2}:${first_time:2:2}:${first_time:4:2}" +%s)
    last_timestamp=$(date -j -f "%T" "${last_time:0:2}:${last_time:2:2}:${last_time:4:2}" +%s)

    time_diff=$((last_timestamp - first_timestamp))

    hours=$((time_diff / 3600))
    minutes=$(((time_diff % 3600) / 60))
    seconds=$((time_diff % 60))

    total_minutes=$((time_diff / 60))
    if [[ "$total_minutes" -gt 0 ]]; then
        cpm=$(echo "scale=2; $total_contacts / $total_minutes" | bc)
    else
        cpm="N/A"
    fi

    total_contacts=$(trim_leading_spaces "$total_contacts")
    echo "Operating Time: ${hours} hours, ${minutes} minutes, ${seconds} seconds"
    echo "Total contacts: $total_contacts"
    echo "Contacts per minute: $cpm"
}

# Function to trim leading spaces
trim_leading_spaces() {
    echo "$1" | sed 's/^[[:space:]]*//'
}

# Count and list unique bands in an ADIF file
count_and_list_unique_bands() {
    local adif_file="$1"
    local unique_bands total_bands BAND_LIST array

    if [[ ! -f "$adif_file" ]]; then
        echo "Error: ADIF file not found."
        return 1
    fi

    unique_bands=$(grep -i '\<BAND\>' "$adif_file" | sed -E 's/.*<BAND>([^<]+)<\/BAND>.*/\1/' | sort | uniq)
    unique_bands=$(echo "$unique_bands" | sed 's/<band:[234]>//g')

    array=($unique_bands)
    unique_bands=$(printf "%s\n" "${array[@]}" | sort -n -t 'm' -k 1,1)

    if [[ -n "$unique_bands" ]]; then
        total_bands=$(echo "$unique_bands" | wc -l)
        printf "Total Bands: %d\n" "$total_bands"

        BAND_LIST=$(echo "$unique_bands" | tr '\n' ' ')
        BAND_LIST=$(echo "$BAND_LIST" | sed "s/${BAND_KEY}3>//g")
        printf "Bands: "
        echo "$BAND_LIST"
    else
        echo "No bands found in the ADIF file."
    fi
}

# Basic file validation
validate_file() {
    FILE="$1"

    if [[ -z "$FILE" || ! -f "$FILE" ]]; then
        echo "Usage: $0 <filename>"
        exit 1
    fi

    invalid_lines=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -n "$line" && "$line" != \<* ]]; then
            echo "❌ Invalid line: $line"
            ((invalid_lines++))
        fi
    done < "$FILE"

    if [[ "$invalid_lines" -ne 0 ]]; then
        echo "❌ Found $invalid_lines invalid line(s) in $FILE."
        exit 1
    fi

    call_count=$(grep -i "$CALL_KEY" "$FILE" | wc -l)

    count=$(get_field_count "${COMMENT_KEY}19>MY_POTA_REF:" "$FILE")
    if [[ "$count" -eq 0 ]]; then
        count=$(get_field_count "${COMMENT_KEY}20>MY_POTA_REF:" "$FILE")
    fi
    if [[ "$count" -eq 0 ]]; then
        count=$(get_field_count "${COMMENT_KEY}19>MY_WWFF_REF:" "$FILE")
    fi
    if [[ "$count" -eq 0 ]]; then
        count=$(get_field_count "${COMMENT_KEY}20>MY_WWFF_REF:" "$FILE")
    fi
    verify_counts "$CALL_KEY" "$call_count" "$COMMENT_KEY" "$count"

    count=$(get_field_count "$RST_SENT_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$RST_SENT_KEY" "$count"

    count=$(get_field_count "$RST_RCVD_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$RST_RCVD_KEY" "$count"

    count=$(get_field_count "$OPERATOR_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$OPERATOR_KEY" "$count"

    count=$(get_field_count "$GRIDSQUARE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$GRIDSQUARE_KEY" "$count"

    count=$(get_field_count "$MYGRIDSQUARE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MYGRIDSQUARE_KEY" "$count"

    count=$(get_field_count "$MY_SIG_INFO_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MY_SIG_INFO_KEY" "$count"

    count=$(get_field_count "$BAND_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$BAND_KEY" "$count"

    count=$(get_field_count "$FREQ_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$FREQ_KEY" "$count"

    count=$(get_field_count "$TIMEON_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$TIMEON_KEY" "$count"

    count=$(get_field_count "$QSODATE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$QSODATE_KEY" "$count"

    count=$(get_field_count "$MODE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MODE_KEY" "$count"

    count=$(get_field_count "$TXPOWER_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$TXPOWER_KEY" "$count"

    count=$(get_field_count "$MYPOTAREF_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MYPOTAREF_KEY" "$count"

    count=$(get_field_count "$NAME_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$NAME_KEY" "$count"

    # Not all callsigns will have states or counties.
    # count=$(get_field_count "$QTH_KEY" "$FILE")
    # verify_counts "$CALL_KEY" "$call_count" "$QTH_KEY" "$count"

    # count=$(get_field_count "$STATE_KEY" "$FILE")
    # verify_counts "$CALL_KEY" "$call_count" "$STATE_KEY" "$count"

    # count=$(get_field_count "$COUNTY_KEY" "$FILE")
    # verify_counts "$CALL_KEY" "$call_count" "$COUNTY_KEY" "$count"

    count=$(get_field_count "$COUNTRY_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$COUNTRY_KEY" "$count"

    count=$(get_field_count "$MYSTATE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MYSTATE_KEY" "$count"

    count=$(get_field_count "$EOR_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$EOR_KEY" "$count"

    verify_brackets "$FILE"

    echo "✅ $FILE seems valid."
}

count_mismatch_error() {
    local FILE="$1"
    local FIELD1="$2"
    local FIELD1COUNT="$3"
    local FIELD2="$4"
    local FIELD2COUNT="$5"

    echo "❌ Mismatch detected in $FILE!"
    echo "\"$FIELD1\" count: $FIELD1COUNT"
    echo "\"$FIELD2\" count: $FIELD2COUNT"
}

get_field_count() {
    local FIELD="$1"
    local FILE="$2"

    grep -i "$FIELD" "$FILE" | wc -l
}

verify_counts() {
    local KEY1="$1"
    local COUNT1="$2"
    local KEY2="$3"
    local COUNT2="$4"

    if [[ "$COUNT1" -ne "$COUNT2" ]]; then
        count_mismatch_error "$FILE" "$KEY1" "$COUNT1" "$KEY2" "$COUNT2"

        echo "Missing field details:"
        list_calls_missing_field "$FILE" "$KEY2"

        # Uncomment this if you want validation to stop immediately on first mismatch:
        # exit 1
    fi
}

verify_brackets() {
    FILE="$1"

    echo "Verifying brackets for $FILE"

    invalid_lines=0
    linenum=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((linenum++))
        opens=$(grep -o '<' <<< "$line" | wc -l)
        closes=$(grep -o '>' <<< "$line" | wc -l)

        if [[ "$opens" -ne "$closes" ]]; then
            echo "❌ Line $linenum: unmatched < and >"
            echo "    $line"
            ((invalid_lines++))
        fi
    done < "$FILE"

    if [[ "$invalid_lines" -ne 0 ]]; then
        echo "❌ Found $invalid_lines line(s) with unmatched < and >"
        exit 1
    fi
}

# Main function to process input and create output files
run() {
    shopt -s nocasematch

    if [ -z "$POTA_PARK" ]; then
        echo "No park reference found. Exiting..."
        exit 1
    fi

    POTA_OUTPUT="${CALLSIGN}@${POTA_PARK}-${DATE}.adi"
    WWFF_OUTPUT="${CALLSIGN}@${WWFF_PARK} ${DATE}.adi"

    echo "POTA Output File: $POTA_OUTPUT"

    if [ "$PROCESSWWFF" -eq 1 ]; then
        echo "WWFF Output File: $WWFF_OUTPUT"
    fi

    checkAndDeleteFile "$POTA_OUTPUT"
    checkAndDeleteFile "$WWFF_OUTPUT"

    # Process POTA
    found_comment="false"
    callsign="false"
    comment="MY_POTA_REF:$POTA_PARK"
    while IFS= read -r line || [[ -n $line ]]; do
        if [[ $line == *"$CALL_KEY"* ]]; then
            callsign="${line#*>}"
        fi

        if [[ $line == *"$EOR_KEY"* ]]; then
            if [ "$found_comment" == "false" ]; then
                echo -e "${RED}Did not find a comment for $callsign! Generating one.${NOCOLOR}"
                echo "$COMMENT_KEY${#comment}>$comment" >> "$POTA_OUTPUT"
            fi
            found_comment="false"
            callsign="false"
        fi

        if [[ $line == *"$COMMENT_KEY"* ]]; then
            found_comment="true"
            echo "$COMMENT_KEY${#comment}>$comment " >> "$POTA_OUTPUT"
        else
            echo "$line" >> "$POTA_OUTPUT"
        fi
    done < "$INPUT"
    echo "Done processing POTA."

    # Process WWFF
    found_comment="false"
    callsign="false"
    comment="MY_WWFF_REF:$WWFF_PARK"
    if [ "$PROCESSWWFF" -eq 1 ]; then
        while IFS= read -r line || [[ -n $line ]]; do
            if [[ $line == *"$CALL_KEY"* ]]; then
                callsign="${line#*>}"
            fi

            if [[ $line == *"$EOR_KEY"* ]]; then
                if [ "$found_comment" == "false" ]; then
                    echo "$COMMENT_KEY${#comment}>$comment" >> "$WWFF_OUTPUT"
                fi
                found_comment="false"
                callsign="false"
            fi

            case $line in
                *"$MY_SIG_KEY"*)
                    echo "${MY_SIG_KEY}4>WWFF" >> "$WWFF_OUTPUT";;
                *"$MY_SIG_INFO_KEY"*)
                    echo "$MY_SIG_INFO_KEY${#WWFF_PARK}>$WWFF_PARK" >> "$WWFF_OUTPUT";;
                *"$COMMENT_KEY"*)
                    comment="MY_WWFF_REF:$WWFF_PARK"
                    found_comment="true"
                    echo "$COMMENT_KEY${#comment}>$comment" >> "$WWFF_OUTPUT";;
                *)
                    echo "$line" >> "$WWFF_OUTPUT";;
            esac
        done < "$INPUT"
        echo "Done processing WWFF."
    fi

    INPUT_COUNT=$(grep -ci "$CALL_KEY" "$INPUT")
    POTA_OUTPUT_COUNT=$(grep -ci "$CALL_KEY" "$POTA_OUTPUT")
    if [ "$PROCESSWWFF" -eq 1 ]; then
        WWFF_OUTPUT_COUNT=$(grep -ci "$CALL_KEY" "$WWFF_OUTPUT")
    fi

    echo "Input file count: $INPUT_COUNT"
    echo "POTA Output file count: $POTA_OUTPUT_COUNT"
    if [ "$PROCESSWWFF" -eq 1 ]; then
        echo "WWFF Output file count: $WWFF_OUTPUT_COUNT"
    fi

    validate_file "$POTA_OUTPUT"

    if [ "$PROCESSWWFF" -eq 1 ]; then
        validate_file "$WWFF_OUTPUT"
    fi

    echo -= STATS =-
    calculate_time_diff "$POTA_OUTPUT"
    list_adif_states "$POTA_OUTPUT"
    count_and_list_unique_bands "$POTA_OUTPUT"

    if [ "$INPUT_COUNT" -ne "$POTA_OUTPUT_COUNT" ]; then
        echo -e "${RED}Error: Count mismatch in POTA file.${NOCOLOR}"
    fi

    if [ "$PROCESSWWFF" -eq 1 ]; then
        if [ "$INPUT_COUNT" -ne "$WWFF_OUTPUT_COUNT" ]; then
            echo -e "${RED}Error: Count mismatch in WWFF file.${NOCOLOR}"
        fi
    fi
}

if [[ "$1" == "help" ]]; then
    displayHelp
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "$INPUT not found!"
    exit 1
fi

initialize_keys

# Extract the first POTA park reference
POTA_PARK=$(grep -oi "${MYPOTAREF_KEY}[78]>[^ ]*" "$INPUT" | head -n 1 | cut -d '>' -f 2)

# No parameter passed in
if [ -z "$1" ]; then
    if [ -z "$POTA_PARK" ]; then
        echo "No park reference found. Exiting..."
        exit 1
    fi

    WWFF_PARK=$(get_key "$POTA_PARK")
    if [[ "$WWFF_PARK" == "null" ]]; then
        echo -e "${RED}The POTA lookup found no WWFF reference.${NOCOLOR}"
        exit 1
    fi
fi

if [ "$1" == "skip" ] || [ "$WWFF_PARK" == "NIL-0000" ]; then
    PROCESSWWFF=0
    echo "Skipping WWFF Processing"
else
    echo -e "POTA:$POTA_PARK = WWFF:$WWFF_PARK"
fi

rename() {
    epoch_time=$(date +%s)

    new_input="${INPUT%.adi}_${epoch_time}.adi"

    mv "$INPUT" "$new_input"
}


run
rename
