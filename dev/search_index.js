var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "#![ClustForOpt-logo](assets/clust_for_opt_text.svg)-1",
    "page": "Introduction",
    "title": "(Image: ClustForOpt logo)",
    "category": "section",
    "text": "(Image: ) (Image: ) (Image: Build Status)ClustForOpt is a julia implementation of clustering methods for finding representative periods for the optimization of energy systems. The package furthermore provides a multi-node capacity expansion model.The package has three main purposes: 1) Provide a simple process of clustering time-series input data, with clustered data output in a generalized type system 2) provide an interface between clustered data and optimization problem 3) provide a generalizable capacity expansion problem formulation and data to test clustering on this problem.The package follows the clustering framework presented in Teichgraeber and Brandt, 2019. The package is actively developed, and new features are continuously added. For a reproducible version of the methods and data of the original paper by Teichgraeber and Brandt, 2019, please refer to branch v0.1-appl_energy-framework-comp.This package is developed by Holger Teichgraeber @holgerteichgraeber and Elias Kuepper @YoungFaithful.If you find ClustForOpt useful in your work, we kindly request that you cite the following paper (link):  @article{Teichgraeber2019,\n  author = {Holger Teichgraeber and Adam Brandt},\n  title = {Clustering methods to find representative periods for the optimization of energy systems: An initial framework and comparison},\n  journal = {Applied Energy},\n  volume = {239},\n  pages = {1283–1293},\n  year = {2019},\n  doi = {https://doi.org/10.1016/j.apenergy.2019.02.012},\n  }"
},

{
    "location": "#Installation-1",
    "page": "Introduction",
    "title": "Installation",
    "category": "section",
    "text": "This package runs under julia v1.0 and higher. Install using:]\nadd https://github.com/holgerteichgraeber/ClustForOpt.jl.gitwhere ] opens the julia package manager."
},

{
    "location": "workflow/#",
    "page": "Workflow",
    "title": "Workflow",
    "category": "page",
    "text": ""
},

{
    "location": "workflow/#Workflow-1",
    "page": "Workflow",
    "title": "Workflow",
    "category": "section",
    "text": "Generally, the workflow requires three steps:load data\nclustering\noptimization"
},

{
    "location": "workflow/#CEP-Specific-Workflow-1",
    "page": "Workflow",
    "title": "CEP Specific Workflow",
    "category": "section",
    "text": "The input data is distinguished between time series independent and time series dependent data. They are kept separate as just the time series dependent data is used to determine representative periods (clustering).(Image: Plot)"
},

{
    "location": "workflow/#Example-Workflow-1",
    "page": "Workflow",
    "title": "Example Workflow",
    "category": "section",
    "text": "using ClustForOpt\n\n# load data (electricity price day ahead market)\nts_input_data, = load_timeseries_data(\"DAM\", \"GER\";K=365, T=24) #DAM\n\n# run standard kmeans clustering algorithm to cluster into 5 representative periods, with 1000 initial starting points\nclust_res = run_clust(ts_input_data;method=\"kmeans\",representation=\"centroid\",n_clust=5,n_init=1000)\n\n# battery operations optimization on the clustered data\nopt_res = run_opt(clust_res)"
},

{
    "location": "load_data/#",
    "page": "Load Data",
    "title": "Load Data",
    "category": "page",
    "text": ""
},

{
    "location": "load_data/#Load-Data-1",
    "page": "Load Data",
    "title": "Load Data",
    "category": "section",
    "text": ""
},

{
    "location": "load_data/#ClustForOpt.load_timeseries_data",
    "page": "Load Data",
    "title": "ClustForOpt.load_timeseries_data",
    "category": "function",
    "text": "load_timeseriesdata(data_path::String; region::String=\"\", K-#Periods, T-#Segments)\n\nLoading all *.csv files in the folder or the file data_path\n\nThe *.csv files shall have the following structure and must have the same length: |Timestamp |[column names...]| |[iterator]|[values]         | The first column should be called Timestamp if it contains a time iterator The other columns can specify the single timeseries like specific geolocation. Each column in [file name].csv file will be added to the ClustData.data called \"[file name]-[column name]\"\n\nregion is an additional String to specify the loaded time series data\nK describes the number of periods in the input data\nT describes the length of each period\n\n\n\n\n\nload_timeseriesdata(application::String, region::String, K-#Periods, T-#Segments)\n\nLoading from .csv files provided with the package in the folder ../ClustForOpt/data/{application}/{region}/TS Timestamp-column has to be called Timestamp Other columns have to be called with the location/node name for application:\n\nDAM: Day Ahead Market\nCEP: Capacity Expansion Problem\n\nand regions:\n\n\"GER_1\": Germany 1 node\n\"GER_18\": Germany 18 nodes\n\"CA_1\": California 1 node\n\"CA_14\": California 14 nodes\n\"TX_1\": Texas 1 node\n\n\n\n\n\n"
},

{
    "location": "load_data/#Load-Timeseries-Data-1",
    "page": "Load Data",
    "title": "Load Timeseries Data",
    "category": "section",
    "text": "load_timeseries_data() loads the data for a given application and region. Possible applications areDAM: Day ahead market price data\nCEP: Capacity Expansion Problem dataPossible regions are:GER: Germany\nCA: California\nTX: TexasThe optional input parameters to load_timeseries_data() are the number of periods K and the number of time steps per period T. By default, they are chosen such that they result in daily time slices.load_timeseries_data"
},

{
    "location": "load_data/#Example-loading-timeseries-data-1",
    "page": "Load Data",
    "title": "Example loading timeseries data",
    "category": "section",
    "text": "using ClustForOpt\nstate=\"GER_1\"\n# laod ts-input-data\nts_input_data, = load_timeseries_data(\"CEP\", state; K=365, T=24)\nusing Plots\nplot(ts_input_data.data[\"solar-germany\"], legend=false, linestyle=:dot, xlabel=\"Time [h]\", ylabel=\"Solar availability factor [%]\")\nsavefig(\"load_timeseries_data.svg\")(Image: Plot)"
},

{
    "location": "load_data/#ClustForOpt.load_cep_data",
    "page": "Load Data",
    "title": "ClustForOpt.load_cep_data",
    "category": "function",
    "text": "load_cep_data(region::String)\n\nLoading from .csv files in a the folder ../ClustForOpt/data/CEP/{region}/ Follow instructions for the CSV-Files:\n\nnodes:       nodes x region, infrastruct, capacity-of-different-tech... in MW_el\nvar_costs:     tech x [USD for fossils: in USD/MWh_el, CO2 in kg-CO₂-eq./MWh_el] # Variable costs per year\nfix_costs:     tech x [USD in USD/MW_el, CO2 in kg-CO₂-eq./MW_el] # Fixed costs per year\ncap_costs:     tech x [USD in USD/MW_el, CO2 in kg-CO₂-eq./MW_el] # Entire (NOT annulized) Costs per Investment in technology\ntechs:        tech x [categ,sector,lifetime in years,effic in %,fuel]\nlines:       lines x [node_start,node_end,reactance,resistance,power,voltage,circuits,length]\n\nfor regions:\n\n\"GER_1\": Germany 1 node\n\"GER_18\": Germany 18 nodes\n\"CA_1\": California 1 node\n\"CA_14\": California 14 nodes\n\"TX_1\": Texas 1 node\n\n\n\n\n\n"
},

{
    "location": "load_data/#Load-CEP-Data-1",
    "page": "Load Data",
    "title": "Load CEP Data",
    "category": "section",
    "text": "load_cep_data() lodes the extra data for the CEP and can take the following regions:GER: Germany\nCA: California\nTX: Texasload_cep_data"
},

{
    "location": "load_data/#Example-loading-CEP-Data-1",
    "page": "Load Data",
    "title": "Example loading CEP Data",
    "category": "section",
    "text": "using ClustForOpt\nstate=\"GER_1\"\n# laod ts-input-data\ncep_data = load_cep_data(state)\ncep_data.fix_costs"
},

{
    "location": "clust/#",
    "page": "Clustering",
    "title": "Clustering",
    "category": "page",
    "text": ""
},

{
    "location": "clust/#Clustering-1",
    "page": "Clustering",
    "title": "Clustering",
    "category": "section",
    "text": "run_clust() takes the full data and gives a struct with the clustered data as the output.   The input parameter n_clust determines the number of clusters,i.e., representative periods."
},

{
    "location": "clust/#ClustForOpt.run_clust",
    "page": "Clustering",
    "title": "ClustForOpt.run_clust",
    "category": "function",
    "text": "run_clust(data::ClustData;norm_op::String=\"zscore\",norm_scope::String=\"full\",method::String=\"kmeans\",representation::String=\"centroid\",n_clust::Int=5,n_init::Int=100,iterations::Int=300,save::String=\"\",attribute_weights::Dict{String,Float64}=Dict{String,Float64}(),get_all_clust_results::Bool=false,kwargs...)\n\nnormop: \"zscore\", \"01\"(not implemented yet) normscope: \"full\",\"sequence\",\"hourly\" method: \"kmeans\",\"kmedoids\",\"kmedoids_exact\",\"hierarchical\" representation: \"centroid\",\"medoid\"\n\n\n\n\n\nrun_clust(data::ClustData,n_clust_ar::Array{Int,1};norm_op::String=\"zscore\",norm_scope::String=\"full\",method::String=\"kmeans\",representation::String=\"centroid\",n_init::Int=100,iterations::Int=300,save::String=\"\",kwargs...)\n\nThis function is a wrapper function around runclust(). It runs multiple number of clusters k and returns an array of results. normop: \"zscore\", \"01\"(not implemented yet) normscope: \"full\",\"sequence\",\"hourly\" method: \"kmeans\",\"kmedoids\",\"kmedoidsexact\",\"hierarchical\" representation: \"centroid\",\"medoid\"\n\n\n\n\n\n"
},

{
    "location": "clust/#Supported-clustering-methods-1",
    "page": "Clustering",
    "title": "Supported clustering methods",
    "category": "section",
    "text": "The following combinations of clustering method and representations are supported by run_clust:Name method representation\nk-means clustering <kmeans> <centroid>\nk-means clustering with medoid representation <kmeans> <medoid>\nk-medoids clustering (partitional) <kmedoids> <medoid>\nk-medoids clustering (exact) [requires Gurobi] <kmedoids_exact> <medoid>\nhierarchical clustering with centroid representation <hierarchical> <centroid>\nhierarchical clustering with medoid representation <hierarchical> <medoid>For use of DTW barycenter averaging (DBA) and k-shape clustering on single-attribute data (e.g. electricity prices), please use branch v0.1-appl_energy-framework-comp.run_clust"
},

{
    "location": "clust/#Opt-Types-1",
    "page": "Clustering",
    "title": "Opt Types",
    "category": "section",
    "text": "InputData\nFullInputData\nClustData\nClustDataMerged\nClustResultAll\nClustResultBest"
},

{
    "location": "clust/#Example-running-clustering-1",
    "page": "Clustering",
    "title": "Example running clustering",
    "category": "section",
    "text": "using ClustForOpt\nstate=\"GER_1\"\n# laod ts-input-data\nts_input_data, = load_timeseries_data(\"CEP\", state; K=365, T=24)\nts_clust_data = run_clust(ts_input_data).best_results\nusing Plots\nplot(ts_clust_data.data[\"solar-germany\"], legend=false, linestyle=:solid, width=3, xlabel=\"Time [h]\", ylabel=\"Solar availability factor [%]\")\nsavefig(\"clust.svg\")(Image: Plot)"
},

{
    "location": "opt/#",
    "page": "Optimization",
    "title": "Optimization",
    "category": "page",
    "text": ""
},

{
    "location": "opt/#Optimization-1",
    "page": "Optimization",
    "title": "Optimization",
    "category": "section",
    "text": "The function run_opt() runs the optimization problem and gives as an output a struct that contains optimal objective function value, decision variables, and additional info. The run_opt() function infers the optimization problem type from the input data. See the example folder for further details.More detailed documentation on the Capacity Expansion Problem can be found in its documentation."
},

{
    "location": "opt_cep/#",
    "page": "Capacity Expansion Problem",
    "title": "Capacity Expansion Problem",
    "category": "page",
    "text": ""
},

{
    "location": "opt_cep/#Capacity-Expansion-Problem-1",
    "page": "Capacity Expansion Problem",
    "title": "Capacity Expansion Problem",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep/#General-1",
    "page": "Capacity Expansion Problem",
    "title": "General",
    "category": "section",
    "text": "The capacity expansion problem (CEP) is designed as a linear optimization model. It is implemented in the algebraic modeling language JUMP. The implementation within JuMP allows to optimize multiple models in parallel and handle the steps from data input to result analysis and diagram export in one open source programming language. The coding of the model enables scalability based on the provided data input, single command based configuration of the setup model, result and configuration collection for further analysis and the opportunity to run design and operation in different optimizations.(Image: Plot)The basic idea for the energy system is to have a spacial resolution of the energy system in discrete nodes. Each node has demand, non-dispatchable generation, dispatachable generation and storage capacities of varying technologies connected to itself. The different energy system nodes are interconnected with each other by transmission lines. The model is designed to minimize social costs by minimizing the following objective function:min sum_accounttechCOST_accountEURUSDtech + sum LL cdot  cost_LL + LE cdot  cos_LE"
},

{
    "location": "opt_cep/#Variables-and-Sets-1",
    "page": "Capacity Expansion Problem",
    "title": "Variables and Sets",
    "category": "section",
    "text": "The models scalability is relying on the usage of sets. The elements of the sets are extracted from the input data and scale the different variables. An overview of the sets is provided in the table. Depending on the models configuration the necessary sets are initialized.name description\nlines transmission lines connecting the nodes\nnodes spacial energy system nodes\ntech fossil and renewable generation as well as storage technologies\nimpact impact categories like EUR or USD, CO 2 − eq., ...\naccount fixed costs for installation and yearly expenses, variable costs\ninfrastruct infrastructure status being either new or existing\nsector energy sector like electricity\ntime K numeration of the representative periods\ntime T numeration of the time intervals within a period\ntime T e numeration of the time steps within a period\ntime I numeration of the time invervals of the full input data periods\ntime I e numeration of the time steps of the full input data periods\ndir transmission direction of the flow uniform with or opposite to the lines directionAn overview of the variables used in the CEP is provided in the table:name dimensions unit description\nCOST [account,impact,tech] EUR/USD, LCA-categories Costs\nCAP [tech,infrastruct,node] MW Capacity\nGEN [sector,tech,t,k,node] MW Generation\nSLACK [sector,t,k,node] MW Power gap, not provided by installed CAP\nLL [sector] MWh LoastLoad Generation gap, not provided by installed CAP\nLE [impact] LCA-categories LoastEmission Amount of emissions that installed CAP crosses the Emission constraint\nINTRASTOR [sector, tech,t,k,node] MWh Storage level within a period\nINTERSTOR [sector,tech,i,node] MWh Storage level between periods of the full time series\nFLOW [sector,dir,tech,t,k,line] MW Flow over transmission line\nTRANS [tech,infrastruct,lines] MW maximum capacity of transmission lines"
},

{
    "location": "opt_cep/#Data-1",
    "page": "Capacity Expansion Problem",
    "title": "Data",
    "category": "section",
    "text": "The package provides data Capacity Expansion Data for:name nodes lines years tech\nGER_1 1 – germany as single node none 2006-2016 Pv, wind, coal, oil, gas, bate, batin, batout, h2e, h2in, h2out, trans\nGER_18 18 – dena-zones within germany 49 2015 Pv, wind, coal, oil, gas, bate, batin, batout, h2e, h2in, h2out, trans\nCA_1 1 - california as single node none 2016 Pv, wind, coal, oil, gas, bate, batin, batout, h2e, h2in, h2out, trans\nCA_14 ! currently not included ! 14 – multiple nodes within CA and neighboring states 46 2016 Pv, wind, coal, oil, gas, bate, batin, batout, h2e, h2in, h2out, trans\nTX_1 1 – single node within Texas none 2008 Pv, wind, coal, nuc, gas, bate, batin, bat_out"
},

{
    "location": "opt_cep/#ClustForOpt.OptDataCEP",
    "page": "Capacity Expansion Problem",
    "title": "ClustForOpt.OptDataCEP",
    "category": "type",
    "text": " OptDataCEP <: OptData\n\n-region::String          name of state or region data belongs to -nodes::DataFrame        nodes x region, infrastruct, capacityofdifferenttech... -`varcosts::DataFrametech x [USD, CO2] -fixcosts::DataFrametech x [USD, CO2] -capcosts::DataFrametech x [USD, CO2] -techs::DataFrame`       tech x [categ,sector,lifetime,effic,fuel,annuityfactor] instead of USD you can also use your favorite currency like EUR\n\n\n\n\n\n"
},

{
    "location": "opt_cep/#ClustForOpt.OptResult",
    "page": "Capacity Expansion Problem",
    "title": "ClustForOpt.OptResult",
    "category": "type",
    "text": "OptResult\n\n\n\n\n\n"
},

{
    "location": "opt_cep/#ClustForOpt.OptVariable",
    "page": "Capacity Expansion Problem",
    "title": "ClustForOpt.OptVariable",
    "category": "type",
    "text": " OptVariable\n\n-data::Array - includes the optimization variable output in  form of an array -axes_names::Array{String,1}- includes the names of the different axes and is equivalent to the sets in the optimization formulation -axes::Tuple- includes the values of the different axes of the optimization variables -type::String` - defines the type of the variable being cv - cost variable - dv -design variable - ov - operating variable - sv - slack variable\n\n\n\n\n\n"
},

{
    "location": "opt_cep/#ClustForOpt.Scenario",
    "page": "Capacity Expansion Problem",
    "title": "ClustForOpt.Scenario",
    "category": "type",
    "text": " Scenario\n\n-descriptor::String -clust_res::ClustResult -opt_res::OptResult\n\n\n\n\n\n"
},

{
    "location": "opt_cep/#Opt-Types-1",
    "page": "Capacity Expansion Problem",
    "title": "Opt Types",
    "category": "section",
    "text": "OptDataCEP\nOptResult\nOptVariable\nScenario"
},

{
    "location": "opt_cep/#ClustForOpt.run_opt",
    "page": "Capacity Expansion Problem",
    "title": "ClustForOpt.run_opt",
    "category": "function",
    "text": "run_opt(ts_data::ClustData,opt_data::OptDataCEP,opt_config::Dict{String,Any};solver::Any=CbcSolver())\n\norganizing the actual setup and run of the CEP-Problem\n\n\n\n\n\n run_opt(ts_data::ClustData,opt_data::OptDataCEP,fixed_design_variables::Dict{String,OptVariable};solver::Any=CbcSolver(),lost_el_load_cost::Number=Inf,lost_CO2_emission_cost::Number)\n\nWrapper function for type of optimization problem for the CEP-Problem (NOTE: identifier is the type of opt_data - in this case OptDataCEP - so identification as CEP problem) This problem runs the operational optimization problem only, with fixed design variables. provide the fixed design variables and the opt_config of the previous step (design run or another opterational run) what you can add to the opt_config:\n\nlost_el_load_cost: Number indicating the lost load price/MWh (should be greater than 1e6),   give Inf for none\nlost_CO2_emission_cost: Number indicating the emission price/kg-CO2 (should be greater than 1e6), give Inf for none\ngive Inf for both lost_cost for no slack\n\n\n\n\n\n run_opt(ts_data::ClustData,opt_data::OptDataCEP,fixed_design_variables::Dict{String,OptVariable};solver::Any=CbcSolver(),descriptor::String=\"\",co2_limit::Number=Inf,lost_el_load_cost::Number=Inf,lost_CO2_emission_cost::Number=Inf,existing_infrastructure::Bool=false,intrastorage::Bool=false)\n\nWrapper function for type of optimization problem for the CEP-Problem (NOTE: identifier is the type of opt_data - in this case OptDataCEP - so identification as CEP problem) options to tweak the model are:\n\ndescritor: String with the name of this paricular model like \"kmeans-10-co2-500\"\nco2_limit: A number limiting the kg.-CO2-eq./MWh (normally in a range from 5-1250 kg-CO2-eq/MWh), give Inf or no kw if unlimited\nlost_el_load_cost: Number indicating the lost load price/MWh (should be greater than 1e6),   give Inf for none\nlost_CO2_emission_cost:\nNumber indicating the emission price/kg-CO2 (should be greater than 1e6), give Inf for none\ngive Inf for both lost_cost for no slack\nexisting_infrastructure: true or false to include or exclude existing infrastructure to the model\nstorage: String \"none\" for no storage or \"simple\" to include simple (only intra-day storage) or \"seasonal\" to include seasonal storage (inter-day)\n\n\n\n\n\n"
},

{
    "location": "opt_cep/#Running-the-Capacity-Expansion-Problem-1",
    "page": "Capacity Expansion Problem",
    "title": "Running the Capacity Expansion Problem",
    "category": "section",
    "text": "note: Note\nThe CEP model can be run with many configurations. The configurations themselves don\'t mess with each other though the provided input data must fulfill the ability to have e.g. lines in order for transmission to work.An overview is provided in the following table:description unit configuration values type default value\nenforce a CO2-limit kg-CO2-eq./MW co2_limit >0 ::Number Inf\nincluding existing infrastructure (no extra costs) - existing_infrastructure true or false ::Bool false\ntype of storage implementation - storage \"none\", \"simple\" or \"seasonal\" ::String \"none\"\nallowing transmission - transmission true or false ::Bool FALSE\nfixing design variables and turning capacity expansion problem into dispatch problem - fixeddesignvariables design variables from design run or nothing ::OptVariables nothing\nallowing lost load (just necessary if design variables fixed) price/MWh lostelload_cost >1e6 ::Number Inf\nallowing lost emission (just necessary if design variables fixed) price/kg_CO2-eq. lostCO2emission_cost >700 ::Number InfThey can be applied in the following way:run_opt"
},

{
    "location": "opt_cep/#Examples-1",
    "page": "Capacity Expansion Problem",
    "title": "Examples",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep/#Example-with-CO2-Limitation-1",
    "page": "Capacity Expansion Problem",
    "title": "Example with CO2-Limitation",
    "category": "section",
    "text": "using ClustForOpt\nstate=\"GER_1\" #select state\nts_input_data, = load_timeseries_data(\"CEP\", state; K=365, T=24)\ncep_data = load_cep_data(state)\nts_clust_data = run_clust(ts_input_data;method=\"kmeans\",representation=\"centroid\",n_init=5,n_clust=5).best_results\nsolver=CbcSolver() # select solver\n# tweak the CO2 level\nco2_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor=\"co2\",co2_limit=500)\nco2_result.status"
},

{
    "location": "opt_cep/#Example-with-slack-variables-included-1",
    "page": "Capacity Expansion Problem",
    "title": "Example with slack variables included",
    "category": "section",
    "text": "slack_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor=\"slack\",lost_el_load_cost=1e6, lost_CO2_emission_cost=700)"
},

{
    "location": "opt_cep/#Example-for-simple-storage-1",
    "page": "Capacity Expansion Problem",
    "title": "Example for simple storage",
    "category": "section",
    "text": "note: Note\nIn simple or intradaystorage the storage level is enforced to be the same at the beginning and end of each day. The variable \'INTRASTORAGE\' is tracking the storage level within each day of the representative periods.simplestor_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor=\"simple storage\",storage=\"simple\")"
},

{
    "location": "opt_cep/#Example-for-seasonal-storage-1",
    "page": "Capacity Expansion Problem",
    "title": "Example for seasonal storage",
    "category": "section",
    "text": "note: Note\nIn seasonalstorage the storage level is enforced to be the same at the beginning and end of the original time-series. The new variable \'INTERSTORAGE\' tracks the storage level throughout the days (or periods) of the original time-series. The variable \'INTRASTORAGE\' is tracking the storage level within each day of the representative periods.seasonalstor_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor=\"seasonal storage\",storage=\"seasonal\",k_ids=run_clust(ts_input_data;method=\"kmeans\",representation=\"centroid\",n_init=5,n_clust=5).best_ids)"
},

{
    "location": "opt_cep/#ClustForOpt.get_cep_variable_set",
    "page": "Capacity Expansion Problem",
    "title": "ClustForOpt.get_cep_variable_set",
    "category": "function",
    "text": "get_cep_variable_set(variable::OptVariable,num_index_set::Int)\n\nGet the variable set from the specific variable and the num_index_set like 1\n\n\n\n\n\nget_cep_variable_set(scenario::Scenario,var_name::String,num_index_set::Int)\n\nGet the variable set from the specific Scenario by indicating the var_name e.g. \"COST\" and the num_index_set like 1\n\n\n\n\n\n"
},

{
    "location": "opt_cep/#ClustForOpt.get_cep_variable_value",
    "page": "Capacity Expansion Problem",
    "title": "ClustForOpt.get_cep_variable_value",
    "category": "function",
    "text": "get_cep_variable_value(variable::OptVariable,index_set::Array)\n\nGet the variable data from the specific Scenario by indicating the var_name e.g. \"COST\" and the index_set like [:;\"EUR\";\"pv\"]\n\n\n\n\n\nget_cep_variable_value(scenario::Scenario,var_name::String,index_set::Array)\n\nGet the variable data from the specific Scenario by indicating the var_name e.g. \"COST\" and the index_set like [:;\"EUR\";\"pv\"]\n\n\n\n\n\n"
},

{
    "location": "opt_cep/#ClustForOpt.get_cep_slack_variables",
    "page": "Capacity Expansion Problem",
    "title": "ClustForOpt.get_cep_slack_variables",
    "category": "function",
    "text": "get_cep_slack_variables(opt_result::OptResult)\n\nReturns all slack variables in this opt_result mathing the type \"sv\"\n\n\n\n\n\n"
},

{
    "location": "opt_cep/#ClustForOpt.get_cep_design_variables",
    "page": "Capacity Expansion Problem",
    "title": "ClustForOpt.get_cep_design_variables",
    "category": "function",
    "text": "get_cep_design_variables(opt_result::OptResult)\n\nReturns all design variables in this opt_result mathing the type \"dv\"\n\n\n\n\n\n"
},

{
    "location": "opt_cep/#Get-Functions-1",
    "page": "Capacity Expansion Problem",
    "title": "Get Functions",
    "category": "section",
    "text": "The get functions allow an easy access to the information included in the result.get_cep_variable_set\nget_cep_variable_value\nget_cep_slack_variables\nget_cep_design_variables"
},

{
    "location": "opt_cep/#Examples-2",
    "page": "Capacity Expansion Problem",
    "title": "Examples",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep/#Example-plotting-Capacities-1",
    "page": "Capacity Expansion Problem",
    "title": "Example plotting Capacities",
    "category": "section",
    "text": "co2_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor=\"co2\",co2_limit=500) #hide\nusing Plots\n# use the get variable set in order to get the labels: indicate the variable as \"CAP\" and the set-number as 1 to receive those set values\nvariable=co2_result.variables[\"CAP\"]\nlabels=get_cep_variable_set(variable,1)\n# use the get variable value function to recieve the values of CAP[:,:,1]\ndata=get_cep_variable_value(variable,[:,:,1])\n# use the data provided for a simple bar-plot without a legend\nbar(data,title=\"Cap\", xticks=(1:length(labels),labels),legend=false)"
},

{
    "location": "opt_cep_data/#",
    "page": "Capacity Expansion Data",
    "title": "Capacity Expansion Data",
    "category": "page",
    "text": ""
},

{
    "location": "opt_cep_data/#Capacity-Expansion-Data-1",
    "page": "Capacity Expansion Data",
    "title": "Capacity Expansion Data",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep_data/#Units-1",
    "page": "Capacity Expansion Data",
    "title": "Units",
    "category": "section",
    "text": "Power - MW Energy - MWh lengths - km"
},

{
    "location": "opt_cep_data/#Setup-for-each-model-1",
    "page": "Capacity Expansion Data",
    "title": "Setup for each model",
    "category": "section",
    "text": "folder-name: [region]-[nodes]   subfolder: TS - containing time-series-data     [dependency].csv |Timestamp| [nodes...]| |–––-|––––| |[some iterator]| relative value of installed capacity for renewables or absolute values for demand or so| |...| ...|"
},

{
    "location": "opt_cep_data/#cap*costs.csv,-fix*costs.csv,-var_costs.csv-1",
    "page": "Capacity Expansion Data",
    "title": "capcosts.csv, fixcosts.csv, var_costs.csv",
    "category": "section",
    "text": "tech [currency] [LCA-Impact categories...]\n[techs] Cost per unit Power(MW) or Energy (MWh) Emissions per unit Power(MW) or Energy (MWh)...\n... ... ..."
},

{
    "location": "opt_cep_data/#nodes.csv-1",
    "page": "Capacity Expansion Data",
    "title": "nodes.csv",
    "category": "section",
    "text": "nodes region infrastruct [techs...]\n[nodes...] region of this node ex for existing or limit for limiting capacity installed capacity of each tech at this node\n... ... ... "
},

{
    "location": "opt_cep_data/#techs.csv-1",
    "page": "Capacity Expansion Data",
    "title": "techs.csv",
    "category": "section",
    "text": "tech categ sector `fuel eff_in eff_out max_gradient time_series lifetime financial_lifetime discount_rate\n[techs...] function handeling those el for electricity fuel dependency efficiency in for storage efficiency out for storage max gradient of this technology time-series dependency of this tech lifetime of an installed cap time in which you have to pay back your loan discount_rate"
},

{
    "location": "opt_cep_data/#lines.csv-1",
    "page": "Capacity Expansion Data",
    "title": "lines.csv",
    "category": "section",
    "text": "|lines|node_start|node_end|reactance|resistance|power|voltage|circuits|length| |[lines...]|node where line starts| node where line ends| reactance| resistance| max power| voltage or description| number of circuits included| length in km|"
},

{
    "location": "opt_cep_data/#GER_1-1",
    "page": "Capacity Expansion Data",
    "title": "GER_1",
    "category": "section",
    "text": "Germany one node,  with existing infrastructure of year 2015, no nuclear"
},

{
    "location": "opt_cep_data/#Time-Series-1",
    "page": "Capacity Expansion Data",
    "title": "Time Series",
    "category": "section",
    "text": "solar: \"RenewableNinja\",  \"Open Power System Data. 2018. Data Package Time series. Version 2018-06-30. https://doi.org/10.25832/time_series/2018-06-30. (Primary data from various sources, for a complete list see URL).\"\nwind: \"RenewableNinja\":  \"Open Power System Data. 2018. Data Package Time series. Version 2018-06-30. https://doi.org/10.25832/time_series/2018-06-30. (Primary data from various sources, for a complete list see URL).\"\neldemand: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016, \"Open Power System Data. 2018. Data Package Time series. Version 2018-06-30. https://doi.org/10.25832/timeseries/2018-06-30. (Primary data from various sources, for a complete list see URL).\""
},

{
    "location": "opt_cep_data/#Installed-CAP-1",
    "page": "Capacity Expansion Data",
    "title": "Installed CAP",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep_data/#nodes-1",
    "page": "Capacity Expansion Data",
    "title": "nodes",
    "category": "section",
    "text": "wind, pv, coal, gas, oil: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016"
},

{
    "location": "opt_cep_data/#Cost-Data-1",
    "page": "Capacity Expansion Data",
    "title": "Cost Data",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep_data/#General-1",
    "page": "Capacity Expansion Data",
    "title": "General",
    "category": "section",
    "text": "economic lifetime T: Glenk, \"Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology\", Glenk, 2019\ncost of capital (WACC), r:  Glenk, \"Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology\", Glenk, 2019"
},

{
    "location": "opt_cep_data/#cap_costs-1",
    "page": "Capacity Expansion Data",
    "title": "cap_costs",
    "category": "section",
    "text": "wind, pv, coal, gas, oil: \"Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor\", Palzer, 2016\ntrans: !Costs for transmission expansion are per MW*km!: \"Zielkonflikte der Energiewende - Life Cycle Assessment der Dekarbonisierung Deutschlands durch sektorenübergreifende Infrastrukturoptimierung\", Reinert, 2018\nbat: \"Konventionelle Kraftwerke - Technologiesteckbrief zur Analyse \'Flexibilitätskonzepte für die Stromversorgung 2050\'\", Görner & Sauer, 2016\nh2: \"Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology\", Glenk, 2019"
},

{
    "location": "opt_cep_data/#fix_costs-1",
    "page": "Capacity Expansion Data",
    "title": "fix_costs",
    "category": "section",
    "text": "wind, pv, gas, bat, h2: Percentages M/O per cap_cost: \"Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor\", Palzer, 2016\noil, coal: assumption oil and coal similar to GuD fix/cap: Percentages M/O per cap_cost: \"Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor\", Palzer, 2016\ntrans: assumption no fix costs"
},

{
    "location": "opt_cep_data/#var_costs-1",
    "page": "Capacity Expansion Data",
    "title": "var_costs",
    "category": "section",
    "text": "coal, gas, oil: Calculation: varcosts_th(Masterthesis Christiane Reinert)/eff(median(eff in ELMOD-DE))\npv, wind, bat, trans: assumption no var costs\nh2: Glenk, \"Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology\", Glenk, 2019"
},

{
    "location": "opt_cep_data/#LCIA-Recipe-H-Midpoint,-GWP-100a-1",
    "page": "Capacity Expansion Data",
    "title": "LCIA Recipe H Midpoint, GWP 100a",
    "category": "section",
    "text": "pv, wind, trans, coal, gas, oil: Ecoinvent v3.3\nbat_e: \"battery cell production, Li-ion, CN\", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5\nh2_in: \"fuel cell CH future 2kW\", Ecoinvent v3.3"
},

{
    "location": "opt_cep_data/#Other-1",
    "page": "Capacity Expansion Data",
    "title": "Other",
    "category": "section",
    "text": "storage: efficiencies are in efficiency per month\nstorage hydrogen: referenced in MWh with lower calorific value 33.32 kWh/kg \"DIN 51850: Brennwerte und Heizwerte gasförmiger Brennstoffe\" 1980\nh2in, h2out: Sunfire process\nh2_e: Cavern"
},

{
    "location": "opt_cep_data/#GER_18-1",
    "page": "Capacity Expansion Data",
    "title": "GER_18",
    "category": "section",
    "text": "Germany 18 (dena) nodes, with existing infrastructure of year 2015, no nuclear"
},

{
    "location": "opt_cep_data/#Time-Series-2",
    "page": "Capacity Expansion Data",
    "title": "Time Series",
    "category": "section",
    "text": "solar: RenewableNinja: geolocation from node with highest pv-Installation 2015, lat, lon, datefrom = \"2014-01-01\", dateto = \"2014-12-31\",capacity = 1.0,dataset=\"merra2\",system_loss = 10,tracking = 0,tilt = 35,azim = 180)\nwind: RenewableNinja: geolocation from node with highest wind-Installation 2015, lat, lon, datefrom = \"2014-01-01\", dateto = \"2014-12-31\",capacity = 1.0,height = 100,turbine = \"Vestas+V80+2000\",dataset=\"merra2\",system_loss = 10)\neldemand: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016, \"Open Power System Data. 2018. Data Package Time series. Version 2018-06-30. https://doi.org/10.25832/timeseries/2018-06-30. (Primary data from various sources, for a complete list see URL).\""
},

{
    "location": "opt_cep_data/#Installed-CAP-2",
    "page": "Capacity Expansion Data",
    "title": "Installed CAP",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep_data/#nodes-2",
    "page": "Capacity Expansion Data",
    "title": "nodes",
    "category": "section",
    "text": "wind, pv, coal, gas, oil: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016"
},

{
    "location": "opt_cep_data/#lines-1",
    "page": "Capacity Expansion Data",
    "title": "lines",
    "category": "section",
    "text": "trans: Open Source Electricity Model for Germany (ELMOD-DE) Data Documentation, Egerer, 2016"
},

{
    "location": "opt_cep_data/#Cost-Data-2",
    "page": "Capacity Expansion Data",
    "title": "Cost Data",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep_data/#cap_costs-2",
    "page": "Capacity Expansion Data",
    "title": "cap_costs",
    "category": "section",
    "text": "wind, pv, coal, gas, oil: \"Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor\", Palzer, 2016\ntrans: !Costs for transmission expansion are per MW*km!: \"Zielkonflikte der Energiewende - Life Cycle Assessment der Dekarbonisierung Deutschlands durch sektorenübergreifende Infrastrukturoptimierung\", Reinert, 2018\nbat: \"Konventionelle Kraftwerke - Technologiesteckbrief zur Analyse \'Flexibilitätskonzepte für die Stromversorgung 2050\'\", Görner & Sauer, 2016\nh2: \"Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology\", Glenk, 2019"
},

{
    "location": "opt_cep_data/#fix_costs-2",
    "page": "Capacity Expansion Data",
    "title": "fix_costs",
    "category": "section",
    "text": "wind, pv, gas, bat, h2: Percentages M/O per cap_cost: \"Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor\", Palzer, 2016\noil, coal: assumption oil and coal similar to GuD fix/cap: Percentages M/O per cap_cost: \"Sektorübergreifende Modellierung und Optimierung eines zukünftigen deutschen Energiesystems unter Berücksichtigung von Energieeffizienzmaßnahmen im Gebäudesektor\", Palzer, 2016\ntrans: assumption no fix costs\nh2: \"Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology\", Glenk, 2019"
},

{
    "location": "opt_cep_data/#var_costs-2",
    "page": "Capacity Expansion Data",
    "title": "var_costs",
    "category": "section",
    "text": "coal, gas, oil: Calculation: varcosts_th(Masterthesis Christiane Reinert)/eff(median(eff in ELMOD-DE))\npv, wind, bat, h2, trans: assumption no var costs"
},

{
    "location": "opt_cep_data/#LCIA-Recipe-H-Midpoint,-GWP-100a-2",
    "page": "Capacity Expansion Data",
    "title": "LCIA Recipe H Midpoint, GWP 100a",
    "category": "section",
    "text": "pv, wind, trans, coal, gas, oil: Ecoinvent v3.3\nbat_e: \"battery cell production, Li-ion, CN\", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5\nh2_in: \"fuel cell CH future 2kW\", Ecoinvent v3.3"
},

{
    "location": "opt_cep_data/#Other-2",
    "page": "Capacity Expansion Data",
    "title": "Other",
    "category": "section",
    "text": "trans efficiency is 0.9995 per km\nlength in kmlength not correct yet demand split up needs improvementstorage: efficiencies are in efficiency per month\nstorage hydrogen: referenced in MWh with lower calorific value 33.32 kWh/kg \"DIN 51850: Brennwerte und Heizwerte gasförmiger Brennstoffe\" 1980\nh2in, h2out: Sunfire process\nh2_e: Cavern"
},

{
    "location": "opt_cep_data/#CA_1-1",
    "page": "Capacity Expansion Data",
    "title": "CA_1",
    "category": "section",
    "text": "California one node"
},

{
    "location": "opt_cep_data/#Time-Series-3",
    "page": "Capacity Expansion Data",
    "title": "Time Series",
    "category": "section",
    "text": "solar, wind, demand: picked region with highest solar and wind installation within california (alt. mean): Ey"
},

{
    "location": "opt_cep_data/#Installed-CAP-3",
    "page": "Capacity Expansion Data",
    "title": "Installed CAP",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep_data/#nodes-3",
    "page": "Capacity Expansion Data",
    "title": "nodes",
    "category": "section",
    "text": "wind, pv, coal, gas, oil: Ey"
},

{
    "location": "opt_cep_data/#lines-2",
    "page": "Capacity Expansion Data",
    "title": "lines",
    "category": "section",
    "text": "trans: Ey"
},

{
    "location": "opt_cep_data/#limits-1",
    "page": "Capacity Expansion Data",
    "title": "limits",
    "category": "section",
    "text": "pv, wind: multiplied by 10"
},

{
    "location": "opt_cep_data/#Cost-Data-3",
    "page": "Capacity Expansion Data",
    "title": "Cost Data",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep_data/#General-2",
    "page": "Capacity Expansion Data",
    "title": "General",
    "category": "section",
    "text": "economic lifetime T: Ey\ncost of capital (WACC), r: Ey"
},

{
    "location": "opt_cep_data/#cap_costs-3",
    "page": "Capacity Expansion Data",
    "title": "cap_costs",
    "category": "section",
    "text": "wind, pv, coal, gas, oil, bat: Ey\ntrans: !Costs for transmission expansion are per MW*km!: \"Zielkonflikte der Energiewende - Life Cycle Assessment der Dekarbonisierung Deutschlands durch sektorenübergreifende Infrastrukturoptimierung\", Reinert, 2018\nh2: \"Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology\", Glenk, 2019"
},

{
    "location": "opt_cep_data/#fix_costs-3",
    "page": "Capacity Expansion Data",
    "title": "fix_costs",
    "category": "section",
    "text": "wind, pv, gas, bat, h2, oil, coal: Ey\ntrans: assumption no fix costs"
},

{
    "location": "opt_cep_data/#var_costs-3",
    "page": "Capacity Expansion Data",
    "title": "var_costs",
    "category": "section",
    "text": "pv, wind, bat, coal, gas, oil: Ey\nh2, trans: assumption no var costs"
},

{
    "location": "opt_cep_data/#LCIA-Recipe-H-Midpoint,-GWP-100a-3",
    "page": "Capacity Expansion Data",
    "title": "LCIA Recipe H Midpoint, GWP 100a",
    "category": "section",
    "text": "pv, wind, trans, coal, gas, oil: Ecoinvent v3.3\nbat_e: \"battery cell production, Li-ion, CN\", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5\nh2_in: \"fuel cell CH future 2kW\", Ecoinvent v3.3\nphp: ref plant: 15484 GWh/a (BEW 2001a). Lifetime is assumed to be 80 years: 4930800000 kg-CO2-eq (recipe-h-midpoint)/plant, 4930800000/(15484 000 MWh/a80a)(80a8760h/a) → CO2-eq/MW, Ecoinvent v3.5"
},

{
    "location": "opt_cep_data/#Other-3",
    "page": "Capacity Expansion Data",
    "title": "Other",
    "category": "section",
    "text": "trans: efficiency is 0.9995 per km\nstorage: efficiencies are in efficiency per month\nstorage hydrogen: referenced in MWh with lower calorific value 33.32 kWh/kg \"DIN 51850: Brennwerte und Heizwerte gasförmiger Brennstoffe\" 1980\nh2in, h2out: Sunfire process\nh2_e: Cavern"
},

{
    "location": "opt_cep_data/#CA_14-1",
    "page": "Capacity Expansion Data",
    "title": "CA_14",
    "category": "section",
    "text": "warning: Implementation\n\'CA_14\' is currently not included in the published data. It will follow shortly.California multiple node"
},

{
    "location": "opt_cep_data/#Time-Series-4",
    "page": "Capacity Expansion Data",
    "title": "Time Series",
    "category": "section",
    "text": "solar, wind, demand: Ey"
},

{
    "location": "opt_cep_data/#Installed-CAP-4",
    "page": "Capacity Expansion Data",
    "title": "Installed CAP",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep_data/#nodes-4",
    "page": "Capacity Expansion Data",
    "title": "nodes",
    "category": "section",
    "text": "wind, pv, coal, gas, oil: Ey"
},

{
    "location": "opt_cep_data/#lines-3",
    "page": "Capacity Expansion Data",
    "title": "lines",
    "category": "section",
    "text": "trans: Ey"
},

{
    "location": "opt_cep_data/#limits-2",
    "page": "Capacity Expansion Data",
    "title": "limits",
    "category": "section",
    "text": "pv, wind: multiplied by 10"
},

{
    "location": "opt_cep_data/#Cost-Data-4",
    "page": "Capacity Expansion Data",
    "title": "Cost Data",
    "category": "section",
    "text": ""
},

{
    "location": "opt_cep_data/#cap_costs-4",
    "page": "Capacity Expansion Data",
    "title": "cap_costs",
    "category": "section",
    "text": "wind, pv, coal, gas, oil, bat: Ey\ntrans: !Costs for transmission expansion are per MW*km!: \"Zielkonflikte der Energiewende - Life Cycle Assessment der Dekarbonisierung Deutschlands durch sektorenübergreifende Infrastrukturoptimierung\", Reinert, 2018\nh2: Glenk, \"Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology\", Glenk, 2019"
},

{
    "location": "opt_cep_data/#fix_costs-4",
    "page": "Capacity Expansion Data",
    "title": "fix_costs",
    "category": "section",
    "text": "wind, pv, gas, bat, h2, oil, coal: Ey\ntrans: assumption no fix costs"
},

{
    "location": "opt_cep_data/#var_costs-4",
    "page": "Capacity Expansion Data",
    "title": "var_costs",
    "category": "section",
    "text": "pv, wind, bat, coal, gas, oil: Ey\ntrans: assumption no var costs\nh2: \"Shared Capacity and Levelized Cost with Application to Power-to-Gas Technology\", Glenk, 2019"
},

{
    "location": "opt_cep_data/#LCIA-Recipe-H-Midpoint,-GWP-100a-4",
    "page": "Capacity Expansion Data",
    "title": "LCIA Recipe H Midpoint, GWP 100a",
    "category": "section",
    "text": "pv, wind, trans, coal, gas, oil: Ecoinvent v3.3\nbat_e: \"battery cell production, Li-ion, CN\", 5.4933 kg CO2-Eq per 0.106 kWh, Ecoinvent v3.5\nh2_in: \"fuel cell CH future 2kW\", Ecoinvent v3.3\nphp: ref plant: 15484 GWh/a (BEW 2001a). Lifetime is assumed to be 80 years: 4930800000 kg-CO2-eq (recipe-h-midpoint)/plant, 4930800000/(15484 000 MWh/a80a)(80a8760h/a) → CO2-eq/MW, Ecoinvent v3.5"
},

{
    "location": "opt_cep_data/#Other-4",
    "page": "Capacity Expansion Data",
    "title": "Other",
    "category": "section",
    "text": "trans: efficiency is 0.9995 per km\nstorage: efficiencies are in efficiency per month\nstorage hydrogen: referenced in MWh with lower calorific value 33.32 kWh/kg \"DIN 51850: Brennwerte und Heizwerte gasförmiger Brennstoffe\" 1980\nh2in, h2out: Sunfire process\nh2_e: Cavern"
},

{
    "location": "opt_cep_data/#TX_1-1",
    "page": "Capacity Expansion Data",
    "title": "TX_1",
    "category": "section",
    "text": "Texas as one node, no existing capacityData from Merrick et al. 2016Implemented with PV-price 0.5 /W   fix: 2.388E+3 /MW  cap: 5.16E+5 /MWAlternatively for price of 1.0/W edit .csv files and replace costs with   fix: 4.776E+3 /MW  cap: 1.032E+6 /MWAssuptions for transformation: demand mulitiplied with 1.48 solar devided by 1000"
},

]}
