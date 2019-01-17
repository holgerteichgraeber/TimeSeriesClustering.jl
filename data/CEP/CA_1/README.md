# CA-1 #
California one node

# Time Series #
- solar, wind, demand: picked region with highest solar and wind installation within california (alt. mean): Ey

# Installed CAP #
## nodes ##
- wind, pv, coal, gas, oil: Ey
## lines ##
- trans: Ey
## limits ##
- pv, wind: multiplied by 10

# Cost Data #
## cap_costs ##
- wind, pv, coal, gas, oil, bat: Ey
- trans: !Costs for transmission expansion are per MW*km!: "Zielkonflikte der Energiewende - Life Cycle Assessment der Dekarbonisierung Deutschlands durch sektorenübergreifende Infrastrukturoptimierung", Reinert, 2018
- h2: "Konventionelle Kraftwerke - Technologiesteckbrief zur Analyse 'Flexibilitätskonzepte für die Stromversorgung 2050'", Görner & Sauer, 2016
## fix_costs ##
- wind, pv, gas, bat, h2, oil, coal: Ey
- trans: assumption no fix costs
## var_costs ##
- pv, wind, bat, coal, gas, oil: Ey
- h2, trans: assumption no var costs

# LCIA Recipe H Midpoint, GWP 100a#
- pv, wind, trans, coal, gas, oil: Ecoinvent v3.3
- bat_e: "battery cell production, Li-ion, CN", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5
- h2_e: "fuel cell CH future 2kW", Ecoinvent v3.3
- php: ref plant: 15484 GWh/a (BEW 2001a). Lifetime is assumed to be 80 years: 4930800000 kg-CO2-eq (recipe-h-midpoint)/plant, 4930800000/(15484 000 MWh/a*80a)(80a*8760h/a) → CO2-eq/MW, Ecoinvent v3.5

# Other #
- trans: efficiency is 0.9995 per km
