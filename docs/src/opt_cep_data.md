# Capacity Expansion Data

## Units
Power - MW
Energy - MWh
lengths - km

### Setup for each model
folder-name: [region]-[nodes]
  subfolder: TS - containing time-series-data
    [dependency].csv
|Timestamp| [nodes...]|
|-------|--------|
|[some iterator]| relative value of installed capacity for renewables or absolute values for demand or so|
|...| ...|
    
### cap_costs.csv, fix_costs.csv, var_costs.csv

| tech  |  [currency] | [LCA-Impact categories...] |
|-------|--------|------------|
|[techs]| Cost per unit Power(MW) or Energy (MWh) | Emissions per unit Power(MW) or Energy (MWh)...|
|...    | ... | ... |

### nodes.csv

|nodes|region|infrastruct|[techs...] |
|-------|--------|------------|--------|
|[nodes...]|region of this node| ex for existing or limit for limiting capacity| installed capacity of each tech at this node|
|...| ...| ...|

### techs.csv
|`tech`|`categ`|`sector`|`fuel|`eff_in`|`eff_out`|`max_gradient`|`time_series`|`lifetime`|`financial_lifetime`|`discount_rate`|
|-------|--------|------|-----|--------|-------|-----------------|------------|----------|--------------------|---------------|
|[techs...]| function handeling those |el for electricity|fuel dependency|efficiency in for storage|efficiency out for storage |max gradient of this technology| time-series dependency of this tech|lifetime of an installed cap|time in which you have to pay back your loan| `discount_rate`|

### lines.csv
|`lines`|`node_start`|`node_end`|`reactance`|`resistance`|`power`|`voltage`|`circuits`|`length`|
|[lines...]|node where line starts| node where line ends| reactance| resistance| max power| voltage or description| number of circuits included| length in km|

## GER_1
Germany one node,  with existing infrastructure of year 2015, no nuclear

### Time Series
- solar: "RenewableNinja",  "Open Power System Data. 2018. Data Package Time series. Version 2018-06-30. https://doi.org/10.25832/time_series/2018-06-30. (Primary data from various sources, for a complete list see URL)."
- wind: "RenewableNinja":  "Open Power System Data. 2018. Data Package Time series. Version 2018-06-30. https://doi.org/10.25832/time_series/2018-06-30. (Primary data from various sources, for a complete list see URL)."
- el_demand: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016, "Open Power System Data. 2018. Data Package Time series. Version 2018-06-30. https://doi.org/10.25832/time_series/2018-06-30. (Primary data from various sources, for a complete list see URL)."

### Installed CAP
#### nodes
- wind, pv, coal, gas, oil: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016

### Cost Data
#### General
- economic lifetime T: Glenk, "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019
- cost of capital (WACC), r:  Glenk, "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019
#### cap_costs
- wind, pv, coal, gas, oil: "Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor", Palzer, 2016
- trans: !Costs for transmission expansion are per MW*km!: "Zielkonflikte der Energiewende - Life Cycle Assessment der Dekarbonisierung Deutschlands durch sektorenübergreifende Infrastrukturoptimierung", Reinert, 2018
- bat: "Konventionelle Kraftwerke - Technologiesteckbrief zur Analyse 'Flexibilitätskonzepte für die Stromversorgung 2050'", Görner & Sauer, 2016
- h2: "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019
#### fix_costs
- wind, pv, gas, bat, h2: Percentages M/O per cap_cost: "Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor", Palzer, 2016
- oil, coal: assumption oil and coal similar to GuD fix/cap: Percentages M/O per cap_cost: "Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor", Palzer, 2016
- trans: assumption no fix costs
#### var_costs
- coal, gas, oil: Calculation: varcosts_th(Masterthesis Christiane Reinert)/eff(median(eff in ELMOD-DE))
- pv, wind, bat, trans: assumption no var costs
- h2: Glenk, "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019

### LCIA Recipe H Midpoint, GWP 100a
- pv, wind, trans, coal, gas, oil: Ecoinvent v3.3
- bat_e: "battery cell production, Li-ion, CN", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5
- h2_in: "fuel cell CH future 2kW", Ecoinvent v3.3

### Other
- storage: efficiencies are in efficiency per month
- storage hydrogen: referenced in MWh with lower calorific value 33.32 kWh/kg "DIN 51850: Brennwerte und Heizwerte gasförmiger Brennstoffe" 1980
- h2_in, h2_out: Sunfire process
- h2_e: Cavern

## GER_18
Germany 18 (dena) nodes, with existing infrastructure of year 2015, no nuclear

### Time Series
- solar: RenewableNinja: geolocation from node with highest pv-Installation 2015, lat, lon, date_from = "2014-01-01", date_to = "2014-12-31",capacity = 1.0,dataset="merra2",system_loss = 10,tracking = 0,tilt = 35,azim = 180)
- wind: RenewableNinja: geolocation from node with highest wind-Installation 2015, lat, lon, date_from = "2014-01-01", date_to = "2014-12-31",capacity = 1.0,height = 100,turbine = "Vestas+V80+2000",dataset="merra2",system_loss = 10)
- el_demand: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016, "Open Power System Data. 2018. Data Package Time series. Version 2018-06-30. https://doi.org/10.25832/time_series/2018-06-30. (Primary data from various sources, for a complete list see URL)."

### Installed CAP
#### nodes
- wind, pv, coal, gas, oil: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016
#### lines
- trans: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016

### Cost Data
#### cap_costs
- wind, pv, coal, gas, oil: "Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor", Palzer, 2016
- trans: !Costs for transmission expansion are per MW*km!: "Zielkonflikte der Energiewende - Life Cycle Assessment der Dekarbonisierung Deutschlands durch sektorenübergreifende Infrastrukturoptimierung", Reinert, 2018
- bat: "Konventionelle Kraftwerke - Technologiesteckbrief zur Analyse 'Flexibilitätskonzepte für die Stromversorgung 2050'", Görner & Sauer, 2016
- h2: "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019
#### fix_costs
- wind, pv, gas, bat, h2: Percentages M/O per cap_cost: "Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor", Palzer, 2016
- oil, coal: assumption oil and coal similar to GuD fix/cap: Percentages M/O per cap_cost: "Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor", Palzer, 2016
- trans: assumption no fix costs
- h2: "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019
#### var_costs
- coal, gas, oil: Calculation: varcosts_th(Masterthesis Christiane Reinert)/eff(median(eff in ELMOD-DE))
- pv, wind, bat, h2, trans: assumption no var costs

### LCIA Recipe H Midpoint, GWP 100a
- pv, wind, trans, coal, gas, oil: Ecoinvent v3.3
- bat_e: "battery cell production, Li-ion, CN", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5
- h2_in: "fuel cell CH future 2kW", Ecoinvent v3.3

### Other
- trans efficiency is 0.9995 per km
- length in km
length not correct yet
demand split up needs improvement
- storage: efficiencies are in efficiency per month
- storage hydrogen: referenced in MWh with lower calorific value 33.32 kWh/kg "DIN 51850: Brennwerte und Heizwerte gasförmiger Brennstoffe" 1980
- h2_in, h2_out: Sunfire process
- h2_e: Cavern

## CA_1
California one node

### Time Series
- solar, wind, demand: picked region with highest solar and wind installation within california (alt. mean): Ey

### Installed CAP
#### nodes
- wind, pv, coal, gas, oil: Ey
#### lines
- trans: Ey
#### limits
- pv, wind: multiplied by 10

### Cost Data
#### General
- economic lifetime T: Ey
- cost of capital (WACC), r: Ey
#### cap_costs
- wind, pv, coal, gas, oil, bat: Ey
- trans: !Costs for transmission expansion are per MW*km!: "Zielkonflikte der Energiewende - Life Cycle Assessment der Dekarbonisierung Deutschlands durch sektorenübergreifende Infrastrukturoptimierung", Reinert, 2018
- h2: "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019
#### fix_costs
- wind, pv, gas, bat, h2, oil, coal: Ey
- trans: assumption no fix costs
#### var_costs
- pv, wind, bat, coal, gas, oil: Ey
- h2, trans: assumption no var costs

### LCIA Recipe H Midpoint, GWP 100a
- pv, wind, trans, coal, gas, oil: Ecoinvent v3.3
- bat_e: "battery cell production, Li-ion, CN", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5
- h2_in: "fuel cell CH future 2kW", Ecoinvent v3.3
- php: ref plant: 15484 GWh/a (BEW 2001a). Lifetime is assumed to be 80 years: 4930800000 kg-CO2-eq (recipe-h-midpoint)/plant, 4930800000/(15484 000 MWh/a*80a)(80a*8760h/a) → CO2-eq/MW, Ecoinvent v3.5

### Other
- trans: efficiency is 0.9995 per km
- storage: efficiencies are in efficiency per month
- storage hydrogen: referenced in MWh with lower calorific value 33.32 kWh/kg "DIN 51850: Brennwerte und Heizwerte gasförmiger Brennstoffe" 1980
- h2_in, h2_out: Sunfire process
- h2_e: Cavern

## CA_14 #
!!! warning "Implementation"
        'CA_14' is currently not included in the published data. It will follow shortly.
California multiple node

### Time Series
- solar, wind, demand: Ey

### Installed CAP
#### nodes
- wind, pv, coal, gas, oil: Ey
#### lines
- trans: Ey
#### limits
- pv, wind: multiplied by 10

### Cost Data
#### cap_costs
- wind, pv, coal, gas, oil, bat: Ey
- trans: !Costs for transmission expansion are per MW*km!: "Zielkonflikte der Energiewende - Life Cycle Assessment der Dekarbonisierung Deutschlands durch sektorenübergreifende Infrastrukturoptimierung", Reinert, 2018
- h2: Glenk, "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019
#### fix_costs
- wind, pv, gas, bat, h2, oil, coal: Ey
- trans: assumption no fix costs
#### var_costs
- pv, wind, bat, coal, gas, oil: Ey
- trans: assumption no var costs
- h2: "Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology", Glenk, 2019

### LCIA Recipe H Midpoint, GWP 100a
- pv, wind, trans, coal, gas, oil: Ecoinvent v3.3
- bat_e: "battery cell production, Li-ion, CN", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5
- h2_in: "fuel cell CH future 2kW", Ecoinvent v3.3
- php: ref plant: 15484 GWh/a (BEW 2001a). Lifetime is assumed to be 80 years: 4930800000 kg-CO2-eq (recipe-h-midpoint)/plant, 4930800000/(15484 000 MWh/a*80a)(80a*8760h/a) → CO2-eq/MW, Ecoinvent v3.5

### Other
- trans: efficiency is 0.9995 per km
- storage: efficiencies are in efficiency per month
- storage hydrogen: referenced in MWh with lower calorific value 33.32 kWh/kg "DIN 51850: Brennwerte und Heizwerte gasförmiger Brennstoffe" 1980
- h2_in, h2_out: Sunfire process
- h2_e: Cavern

## TX_1
Texas as one node, no existing capacity

Data from Merrick et al. 2016

Implemented with PV-price 0.5 $/W
  fix: 2.388E+3 $/MW  cap: 5.16E+5 $/MW

Alternatively for price of 1.0$/W edit .csv files and replace costs with
  fix: 4.776E+3 $/MW  cap: 1.032E+6 $/MW

Assuptions for transformation:
demand mulitiplied with 1.48
solar devided by 1000
