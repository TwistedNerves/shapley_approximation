#using Random, Distributions, Combinatorics, JLD2
using Pkg
Pkg.instantiate()
using Random
using Distributions
using Combinatorics
using JLD2

include("./instance_generation.jl")
include("./shapley_algorithms.jl")


function average_normalized_error2(target::Vector{Float64}, x::Vector{Float64}, epsilon::Float64=10^-1)::Float64
    size = length(target)
    mean = 0.
    for i in 1:size
        if target[i] != 0. mean += abs.(target[i] .- x[i])./abs.(target[i]) end
    end
    return mean / size
end

function average_normalized_error(target::Vector{Float64}, x::Vector{Float64}, epsilon::Float64=10^-1)::Float64
    size = length(target)
    normalized_error = abs.(target .- x)./max.(abs.(target), epsilon)
    return sum(normalized_error) / size
end

function average_error(target::Vector{Float64}, x::Vector{Float64}, epsilon::Float64=10^-1)::Float64
    return sum(abs.(target .- x)) / length(target)
end


function instance_name_from_index(index::Int64, path::String)::String
    list_files = readdir(path)
    sort!(list_files)
	return list_files[index]
end


global_path = "/pfcalcul/work/flamothe"
# global_path = "/home/francois-lamothe/Desktop"

arg_init = parse(Int64, ARGS[1]) - 1
#arg_init = 12023

# dataset_list = ["random_sparse", "random", "monotone_sparse", "monotone", "voting", "airport", "knapsack"]
# dataset_list = ["varying_sparseness", "varying_variance_tradeoff", "voting", "airport", "knapsack"]
dataset_list = ["weighted_graph"]
algorithm_list = ["kernel", "mc no stratif", "mc position stratif", "mc player stratif", "mc both stratif", "cc position stratif", "cc both stratif", "cc position stratif neyman", "mc position stratif neyman"]
nb_instances = 80
sample_multiplier_list = [1, 4, 20, 100]
# sample_multiplier_list = [300, 1000]
arg= arg_init
instance_index, arg = arg % nb_instances + 1, arg÷nb_instances
sample_multiplier_index, arg = arg % length(sample_multiplier_list) + 1, arg÷length(sample_multiplier_list)
algorithm_index, dataset_index = arg % length(algorithm_list) + 1, arg÷length(algorithm_list) + 1
algorithm_name, dataset_name = algorithm_list[algorithm_index], dataset_list[dataset_index]
sample_multiplier = sample_multiplier_list[sample_multiplier_index]

dir_path = "$(global_path)/shapley_approximation/datasets/$(dataset_name)"
instance_name = instance_name_from_index(instance_index, dir_path)

file_path = "$(dir_path)/$(instance_name)"
evaluation_function, shapley_evaluator = read_symetric_sum_instance(file_path)

nb_underscore_in_dataset_name = count(i->(i=='_'), dataset_name)
nb_players = parse(Int64, collect(split(instance_name, "_"))[nb_underscore_in_dataset_name + 2])

true_shap = shapley_evaluator()

nb_samples = sample_multiplier * nb_players * nb_players
println("Launching Algo $((algorithm_name, dataset_name, nb_players, instance_index, nb_samples))")

if algorithm_name == "kernel" result = kernel_shapley_values(evaluation_function, nb_players, nb_samples) end
if algorithm_name == "mc no stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, player_stratification=false, position_stratification=false) end
if algorithm_name == "mc position stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, player_stratification=false) end
if algorithm_name == "mc player stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, position_stratification=false) end
if algorithm_name == "mc both stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples) end
if algorithm_name == "cc position stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, contribution="complementary", player_stratification=false) end
if algorithm_name == "cc both stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, contribution="complementary") end
if algorithm_name == "cc position stratif neyman" result = complementary_contribution_neyman_allocation_shapley_values(evaluation_function, nb_players, nb_samples) end
if algorithm_name == "mc position stratif neyman" result = stratified_position_sampling_castro_values(evaluation_function, nb_players, nb_samples) end

efficicency = average_error(true_shap, result)
# efficicency = average_normalized_error(true_shap, result)
save_file_path = "$(global_path)/shapley_approximation/results/results_$(arg_init).jld2"
save_object(save_file_path, (algorithm_name, dataset_name, nb_players, instance_index, nb_samples, efficicency))
