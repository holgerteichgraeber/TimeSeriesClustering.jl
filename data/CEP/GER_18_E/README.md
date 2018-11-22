# GER_18_E #
Germany 18 (dena) nodes, existing infrastructure of year 2015, no nuclear

TS for pv: RenewableNinja: geolocation from node with highest pv-Installation 2015, lat, lon, date_from = "2014-01-01", date_to = "2014-12-31",capacity = 1.0,dataset="merra2",system_loss = 10,tracking = 0,tilt = 35,azim = 180)
TS for wind: RenewableNinja: geolocation from node with highest wind-Installation 2015, lat, lon, date_from = "2014-01-01", date_to = "2014-12-31",capacity = 1.0,height = 100,turbine = "Vestas+V80+2000",dataset="merra2",system_loss = 10)
TS for el_demand: ELMOD_DE
cap_costs: Masterthesis Christiane Reinert, Ecoinvent
fix_costs: none
var_costs: varcosts_th(Masterthesis Christiane Reinert)/eff(median(eff in ELMOD-DE))

