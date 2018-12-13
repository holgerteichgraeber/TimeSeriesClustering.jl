## GER_1 ##
Germany one node,  with existing infrastructure of year 2015, no nuclear

# Time Series #
TS for solar: RenewableNinja: geolocation from node with highest pv-Installation 2015, lat, lon, date_from = "2014-01-01", date_to = "2014-12-31",capacity = 1.0,dataset="merra2",system_loss = 10,tracking = 0,tilt = 35,azim = 180)
TS for wind: RenewableNinja: geolocation from node with highest wind-Installation 2015, lat, lon, date_from = "2014-01-01", date_to = "2014-12-31",capacity = 1.0,height = 100,turbine = "Vestas+V80+2000",dataset="merra2",system_loss = 10)
TS for el_demand: ELMOD_DE

# Cost Data #
cap_costs: Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor, A. Palzer Ecoinvent,
Masterthesis Christiane Reinert,
Allelein
Total battery cost of a Li-ion battery is composed of bidirectional umrichter 180EUR/kW and battery with 580EUR/kW in 2013, Energiesysteme Zukunft
fix_costs: Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor, A. Palzer, assumption oil and coal similar to GuD fix/cap
var_costs: varcosts_th(Masterthesis Christiane Reinert)/eff(median(eff in ELMOD-DE))
! Costs for transmission expansion are per MW*km!

# LCIA Recipe H Midpoint, GWP 100a#
Ecoinvent v3.3:
pv, wind,
Ecoinvent 3.5:
bat_st_e: battery cell production, Li-ion, CN, 5.4933 kg CO2-Eq per 0.106 kWh

# Other #
