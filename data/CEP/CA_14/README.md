# CA-14 #
California multiple node

# Time Series #
- solar, wind, demand: Ey

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
- h2: Glenk, "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019
## fix_costs ##
- wind, pv, gas, bat, h2, oil, coal: Ey
- trans: assumption no fix costs
## var_costs ##
- pv, wind, bat, coal, gas, oil: Ey
- trans: assumption no var costs
- h2: "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019

# LCIA Recipe H Midpoint, GWP 100a#
- pv, wind, trans, coal, gas, oil: Ecoinvent v3.3
- bat_e: "battery cell production, Li-ion, CN", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5
- h2_in: "fuel cell CH future 2kW", Ecoinvent v3.3
- php: ref plant: 15484 GWh/a (BEW 2001a). Lifetime is assumed to be 80 years: 4930800000 kg-CO2-eq (recipe-h-midpoint)/plant, 4930800000/(15484 000 MWh/a*80a)(80a*8760h/a) → CO2-eq/MW, Ecoinvent v3.5

# Other #
- trans: efficiency is 0.9995 per km
- storage: efficiencies are in efficiency per month
- storage hydrogen: referenced in MWh with lower calorific value 33.32 kWh/kg "DIN 51850: Brennwerte und Heizwerte gasförmiger Brennstoffe" 1980
- h2_in, h2_out: Sunfire process
- h2_e: Cavern
