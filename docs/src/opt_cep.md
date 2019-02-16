# Capacity Expansion Problem

## General
The capacity expansion problem (CEP) is designed as a linear optimization model. It is implemented in the algebraic modeling language [JUMP](http://www.juliaopt.org/JuMP.jl/latest/). The implementation within JuMP allows to optimize multiple models in parallel and handle the steps from data input to result analysis and diagram export in one open source programming language. The coding of the model enables scalability based on the provided data input, single command based configuration of the setup model, result and configuration collection for further analysis and the opportunity to run design and operation in different optimizations.

![drawing](https://raw.githubusercontent.com/YoungFaithful/ClustForOpt_priv.jl/master/data/CEP/CEP.png?token=AKEm3aahRMwN8Xc08CsO9zo7ebbDwDAoks5cbG7DwA%3D%3D)
The basic idea for the energy system is to have a spacial resolution of the energy system in discrete nodes. Each node has demand, non-dispatchable generation, dispatachable generation and storage capacities of varying technologies connected to itself. The different energy system nodes are interconnected with each other by transmission lines.
The model is designed to minimize social costs by minimizing the following objective function:

```math
min \sum_{account,tech}COST_{account,'EUR/USD',tech} + \sum LL \cdot  cost_{LL} + LE \cdot  cos_{LE}
```

## Variables and Sets
The models scalability is relying on the usage of sets. The elements of the sets are extracted from the input data and scale the different variables. An overview of the sets is provided in the table. Depending on the models configuration the necessary sets are initialized.
```@raw html
<table>
  <tr>
    <th>name</th>
    <th>description</th>
  </tr>
  <tr>
    <td>lines</td>
    <td>transmission lines connecting the nodes</td>
  </tr>
  <tr>
    <td>nodes</td>
    <td>spacial energy system nodes</td>
  </tr>
  <tr>
    <td>tech</td>
    <td>generation and storage technologies</td>
  </tr>
  <tr>
    <td>impact</td>
    <td>impact categories like EUR\USD, kg-CO_2−eq., ...</td>
  </tr>
  <tr>
    <td>account</td>
    <td> fixed costs (for installation and yearly expenses) & variable costs</td>
  </tr>
  <tr>
    <td>infrastruct</td>
    <td>infrastructure status being either new or existing</td>
  </tr>
  <tr>
    <td>sector</td>
    <td>energy sector like electricity</td>
  </tr>
  <tr>
    <td>time K</td>
    <td>numeration of the representative periods</td>
  </tr>
  <tr>
    <td>time T</td>
    <td>numeration of the time intervals within a period</td>
  </tr>
  <tr>
    <td>time T-e</td>
    <td>numeration of the time steps within a period</td>
  </tr>
  <tr>
    <td>time I</td>
    <td>numeration of the time invervals of the full input data periods</td>
  </tr>
  <tr>
    <td>time I-e</td>
    <td>numeration of the time steps of the full input data periods</td>
  </tr>
  <tr>
    <td>dir transmission</td>
    <td>direction of the flow uniform with or opposite to the lines direction</td>
  </tr>
</table>
```

An overview of the variables used in the CEP is provided in the table:
```@raw html
<table>
  <tr>
    <th>name</th>
    <th>dimensions</th>
    <th>unit</th>
    <th>description</th>
  </tr>
  <tr>
    <td>COST</td>
    <td>[account,impact,tech]</td>
    <td>EUR/USD, LCA-categories</td>
    <td>Costs</td>
  </tr>
  <tr>
    <td>CAP</td>
    <td>[tech,infrastruct,node]</td>
    <td>MW</td>
    <td>Capacity</td>
  </tr>
  <tr>
    <td>GEN</td>
    <td>[sector,tech,t,k,node]</td>
    <td>MW</td>
    <td>Generation</td>
  </tr>
  <tr>
    <td>SLACK</td>
    <td>[sector,t,k,node]</td>
    <td>MW</td>
    <td>Power gap, not provided by installed CAP</td>
  </tr>
  <tr>
    <td>LL</td>
    <td>[sector]</td>
    <td>MWh</td>
    <td>LoastLoad Generation gap, not provided by installed CAP</td>
  </tr>
  <tr>
    <td>LE</td>
    <td>[impact]</td>
    <td>LCA-categories</td>
    <td>LoastEmission Amount of emissions that installed CAP crosses the Emission constraint</td>
  </tr>
  <tr>
    <td>INTRASTOR</td>
    <td>[sector, tech,t,k,node]</td>
    <td>MWh</td>
    <td>Storage level within a period</td>
  </tr>
  <tr>
    <td>INTERSTOR</td>
    <td>[sector,tech,i,node]</td>
    <td>MWh</td>
    <td>Storage level between periods of the full time series</td>
  </tr>
  <tr>
    <td>FLOW</td>
    <td>[sector,dir,tech,t,k,line]</td>
    <td>MW</td>
    <td>Flow over transmission line</td>
  </tr>
  <tr>
    <td>TRANS</td>
    <td>[tech,infrastruct,lines]</td>
    <td>MW</td>
    <td>maximum capacity of transmission lines</td>
  </tr>
</table>
```

## Data
The package provides data [Capacity Expansion Data](@ref) for:
```@raw html
<table>
  <tr>
    <th>name</th>
    <th>nodes</th>
    <th>lines</th>
    <th>years</th>
    <th>tech</th>
  </tr>
  <tr>
    <td>GER_1</td>
    <td>1 – germany as single node</td>
    <td>none</td>
    <td>2006-2016</td>
    <td>Pv, wind, coal, oil, gas, bat_e, bat_in, bat_out, h2_e, h2_in, h2_out, trans</td>
  </tr>
  <tr>
    <td>GER_18</td>
    <td>18 – dena-zones within germany</td>
    <td>49</td>
    <td>2015</td>
    <td>Pv, wind, coal, oil, gas, bat_e, bat_in, bat_out, h2_e, h2_in, h2_out, trans</td>
  </tr>
  <tr>
    <td>CA_1</td>
    <td>1 - california as single node</td>
    <td>none</td>
    <td>2016</td>
    <td>Pv, wind, coal, oil, gas, bat_e, bat_in, bat_out, h2_e, h2_in, h2_out, trans</td>
  </tr>
  <tr>
    <td>CA_14</td>
    <td>14 – multiple nodes within CA and neighboring states</td>
    <td>46</td>
    <td>2016</td>
    <td>Pv, wind, coal, oil, gas, bat_e, bat_in, bat_out, h2_e, h2_in, h2_out, trans</td>
  </tr>
  <tr>
    <td>TX_1</td>
    <td>1 – single node within Texas</td>
    <td>none</td>
    <td>2008</td>
    <td>Pv, wind, coal, nuc, gas, bat_e, bat_in, bat_out</td>
  </tr>
</table>
```

## Opt Types
```@docs
OptDataCEP
OptResult
OptVariable
Scenario
```

## Running the Capacity Expansion Problem

!!! note
    The CEP model can be run with many configurations. The configurations themselves don't mess with each other though the provided input data must fulfill the ability to have e.g. lines in order for transmission to work.

An overview is provided in the following table:
```@raw html
<table>
  <tr>
    <th>description</th>
    <th><br>unit<br></th>
    <th>configuration</th>
    <th>values</th>
    <th>type</th>
    <th>default value</th>
  </tr>
  <tr>
    <td>enforce a CO2-limit</td>
    <td>kg-CO2-eq./MW<br></td>
    <td>co2_limit</td>
    <td>&gt;0</td>
    <td>::Number</td>
    <td>Inf</td>
  </tr>
  <tr>
    <td>including existing infrastructure (no extra costs)</td>
    <td>-<br></td>
    <td>existing_infrastructure</td>
    <td>true or false</td>
    <td>::Bool</td>
    <td>false<br></td>
  </tr>
  <tr>
    <td>type of storage implementation</td>
    <td>-</td>
    <td>storage</td>
    <td>"none", "simple" or "seasonal"</td>
    <td>::String</td>
    <td>"none"<br></td>
  </tr>
  <tr>
    <td>allowing transmission</td>
    <td>-</td>
    <td>transmission</td>
    <td>true or false</td>
    <td>::Bool</td>
    <td>false</td>
  </tr>
  <tr>
    <td>fixing design variables and turning capacity expansion problem into dispatch problem</td>
    <td>-</td>
    <td>fixed_design_variables</td>
    <td>design variables from design run or nothing</td>
    <td>::OptVariables</td>
    <td>nothing</td>
  </tr>
  <tr>
    <td>allowing lost load (just necessary if design variables fixed)</td>
    <td>price/MWh</td>
    <td>lost_el_load_cost</td>
    <td>&gt;1e6</td>
    <td>::Number</td>
    <td>Inf</td>
  </tr>
  <tr>
    <td>allowing lost emission (just necessary if design variables fixed)</td>
    <td>price/kg_CO2-eq.</td>
    <td>lost_CO2_emission_cost</td>
    <td>&gt;700</td>
    <td>::Number</td>
    <td>Inf</td>
  </tr>
</table>
```

They can be applied in the following way:
```@docs
run_opt
```

### Examples
#### Example with CO2-Limitation
```@example
using ClustForOpt
using Gurobi
state="GER_1" #select state
ts_input_data, = load_timeseries_data("CEP", state; K=365, T=24)
cep_data = load_cep_data(state)
ts_clust_data = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=5,n_clust=5).best_results
solver=GurobiSolver(OutputFlag=0) # select solver
# tweak the CO2 level
co2_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor="co2",co2_limit=500)
co2_result.status
```
```@setup cep
using Plots
using ClustForOpt
using Gurobi
state="GER_1"
ts_input_data, = load_timeseries_data("CEP", state; K=365, T=24)
cep_data = load_cep_data(state)
ts_clust_data = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=5,n_clust=5).best_results
solver=GurobiSolver(OutputFlag=0)
```
#### Example with slack variables included
```@example cep
slack_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor="slack",lost_el_load_cost=1e6, lost_CO2_emission_cost=700)
slack_result.status
```
#### Example for simple storage
!!! note
    In simple or intradaystorage the storage level is enforced to be the same at the beginning and end of each day. The variable 'INTRASTORAGE' is tracking the storage level within each day of the representative periods.
```@example cep
simplestor_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor="simple storage",storage="simple")
simplestor_result.status
```
#### Example for seasonal storage
!!! note
    In seasonalstorage the storage level is enforced to be the same at the beginning and end of the original time-series. The new variable 'INTERSTORAGE' tracks the storage level throughout the days (or periods) of the original time-series. The variable 'INTRASTORAGE' is tracking the storage level within each day of the representative periods.
```@example cep
seasonalstor_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor="seasonal storage",storage="seasonal",k_ids=run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=5,n_clust=5).best_ids)
seasonalstor_result.status
```
## Get Functions
The get functions allow an easy access to the information included in the result.
```@docs
get_cep_variable_set
get_cep_variable_value
get_cep_slack_variables
get_cep_design_variables
```
### Examples
#### Example plotting Capacities

```@example cep
co2_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor="co2",co2_limit=500) #hide
using Plots
# use the get variable set in order to get the labels: indicate the variable as "CAP" and the set-number as 1 to receive those set values
variable=co2_result.variables["CAP"]
labels=get_cep_variable_set(variable,1)
# use the get variable value function to recieve the values of CAP[:,:,1]
data=get_cep_variable_value(variable,[:,:,1])
# use the data provided for a simple bar-plot without a legend
bar(data,title="Cap", xticks=(1:length(labels),labels),legend=false)
```
